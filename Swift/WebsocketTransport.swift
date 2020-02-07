//
//  WebsocketTransport.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 21.10.2019.
//

import Foundation
import Starscream

//Класс, реализующий логику передачи сообщений через Websocket соединение.

///
/// Класс, реализующий логику передачи сообщений через Websocket соединение.
///
final class WebsocketTransport: Transport {

    // MARK: - Properties

    weak var delegate: TransportDelegate?

    private let messageFactory: MessageFactory
    private let configuration: VPS.Configuration

    private var socket: WebSocket?
    private(set) var delayedMessages = [Message]()

    private var logger = Logger()

    private var timeoutTimer: Timer?
    private var isConnected: Bool { return socket?.isConnected ?? false }

    // MARK: - Initializers

    /// Инициализатор WebSocket транспорта для работы с VPS
    ///
    /// - Parameter configuration: Модель настроек для сервиса Voice Processing Service API.
    /// - Parameter messageFactory: Фабрика по созданию сообщений под соответствующий протокол
    /// соединения.
    init(
        configuration: VPS.Configuration,
        messageFactory: MessageFactory,
        websocketCreator: @escaping (URL) -> WebSocket = { return WebSocket(url: $0) }
    ) {
        self.messageFactory = messageFactory
        self.configuration = configuration
        self.websocketCreator = websocketCreator
        self.logger.enableLoging = configuration.enableLogging
    }

    private let websocketCreator: (URL) -> WebSocket

    // MARK: - <Transport>

    func send(message: Message) {
        if isConnected {
            sendInstantly(message: message)
        } else {
            delayedMessages.append(message)
            guard socket == nil else { return }
            openSocket()
        }
    }

    // MARK: - Methods

    private func sendInstantly(message: Message) {
        guard var data = try? message.binaryData() else {
            closeSocket()
            return
        }
        let length: Int32 = Int32(data.count)
        let lengthData = withUnsafeBytes(of: length) { Data($0) }
        data = lengthData + data

        logger.log("socket sent data with: \(data)")
        logger.log("message:\n\(message.description())")
        logger.log(data)

        socket?.write(data: data)
    }

    private func openSocket() {
        guard let socket = instantiateSocket() else { return }
        self.socket = socket
        connect(socket: socket, availableTimeout: configuration.connectionTimeout)
    }

    private func instantiateSocket() -> WebSocket? {
        guard let url = URL(string: configuration.host) else { return nil }

        let socket = websocketCreator(url)
        socket.delegate = self
        if configuration.sslEnable {//, let certificates = configuration.sslCertificates {
//            let directive = CertificateDirective(certificates: certificates)
//            directive.enableSelfSignedCertificates = true
//            socket.security = directive
            //Note: Для прохождения валидации на самоподписанных сертификатах, необходимо выключить
            //валидацию на уровне Starscream
            socket.disableSSLCertValidation = true
        }
        return socket
    }

    private func connect(socket: WebSocket, availableTimeout: TimeInterval) {
        socket.connect()
        startTimeoutTimer()
    }

    private func startTimeoutTimer() {
        stopTimeoutTimer()
        timeoutTimer = Timer.scheduledTimer(timeInterval: configuration.connectionTimeout,
                                            target: self,
                                            selector: #selector(didFailWithTimeout),
                                            userInfo: nil,
                                            repeats: false)
    }

    private func stopTimeoutTimer() {
        if let timer = timeoutTimer, timer.isValid {
            timer.invalidate()
        }
        timeoutTimer = nil
    }

    @objc private func didFailWithTimeout() {
        logger.log("socket has reached connection timeout")
        delegate?.lostConnection(with: VPS.Errors.connectionError)
    }

    private func closeSocket() {
        socket?.disconnect()
        stopTimeoutTimer()
    }
}

// MARK: - WebSocketDelegate
extension WebsocketTransport: WebSocketDelegate {

    func websocketDidConnect(socket: WebSocketClient) {
        logger.log("socket has connected")
        logger.log("has \(delayedMessages.count) delayed messages")

        delegate?.estabilshedConnection()

        stopTimeoutTimer()

        delayedMessages.forEach { message in
            sendInstantly(message: message)
        }
        delayedMessages = []
    }

    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        logger.log("socket has disconnected with error \(error?.localizedDescription ?? "")")

        self.socket = nil
        delegate?.lostConnection(with: error)
    }

    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        logger.log("socket has received text")
    }

    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        logger.log("socket has received data \(data.count)")
        logger.log(data)

        var messages = [Message]()

        /*
        Маршрутизаторы могут склеивать ответные пакеты, поэтому приходящие с сервера
        пакеты имеют определённый формат – заголовок в 4 байта и тело.
        В заголовке записана длина байтов тела, поэтому необходимо реализовать
        рекурсивную логику чтения.

        Пример полученного пакета изображён ниже:
        1111XXXXXXXXX1111XXXXX1111XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
        1111 – это заголовок, длиной в 4 байта, содержит в себе длину тела;
        XXXX – это тело, содержащее в себе сериализованные данные Protobuf.

        Ниже реализована логика рекурсивного парсинга исходного массива байт и десериализации
        их в исходные Message.
        Принцип следующий:
        1. Устанавливаем указатель (pos) на нулевой индекс массива байт
        2. Читаем 4 байта, начиная с pos
        3. Читаем Int-значение, хранящееся в этих 4-х байтах (lengthOfData)
        4. Смещаем указатель на 5-й по счёту байт
        5. Читаем lengthOfData байт
        6. Пытаемся десериализовать прочитанные байты в Message
        7. Перемещаем указать на конец считанного диапазона
        8. Повторяем с пункта 1 до тех пор пока не прочитаем все байты
        По логике не должно быть ситуаций, когда остаются байты,
        которые не попали ни в одно из Message, для этого в конце цикла есть доп. проверка.
        */

        var pos = 0
        while pos < data.count {
            guard pos + 3 < data.count else { break }
            let lengthChunk = NSData(data: data.subdata(in: pos..<(pos + 4)))
            var lengthOfData = 0

            lengthChunk.getBytes(&lengthOfData, length: MemoryLayout<Int>.size)

            pos += 4
            guard pos + lengthOfData <= data.count else { break }
            let body = data.subdata(in: pos..<(pos + lengthOfData))

            guard let message = try? messageFactory.createMessage(data: body) else { break }
            messages.append(message)
            pos += lengthOfData
        }

        let leftBytesCount = data.count - pos
        if leftBytesCount > 0 {
            logger.log("socket has some remaining data \(leftBytesCount)")
        }

        messages.forEach { message in
            logger.log("message:\n\(message.description())")
            delegate?.received(message: message)
        }
    }
}








struct Logger {
    
    var enableLoging: Bool = false
    
    func log(_ string: String) {
        if enableLoging {
            print(string)
        }
    }
    
    func log(_ data: Data) {
        if enableLoging {
            var string  = ""
            for byte in data {
                string.append("\(byte) ")
            }
            print(string)
        }
    }

}
