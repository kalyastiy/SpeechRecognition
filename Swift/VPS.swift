//
//  VPS.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 21.10.2019.
//

import Foundation

//Протокол по работе с VPS-сервисом. Обращаться к нему должны VPS.session
protocol VPSProtocol: AnyObject {
    
    //Создание текстового запроса к сервису VPS, предполагается что на текстовый запрос должен вернуться текстовый ответ
    //и голосовой поток ответа (в случае включенной озвучки)
    func send(text: String, session: ProcessingSession)
    
    //Создание голосового запрсоа к сервису VPS, предполагается что на текстовый(голосовой) запрос должен вернутся распознанный надиктованный текст,
    //послего него текстовый ответ и голосовой поток овтета(в случае включения озвучки)
    //Для завершения передачи голоса необходимо передать в последнем сообщении флаг last=true. После передачи данного флага на backend запустится
    //процесс обработки и подготовки ответа
    func send(voice: Data, session: ProcessingSession, last: Bool)
    
    //Отменяет запросы в активной сессии, приводит к вызову метода sessiom:finished:canceled=true в Session.Delegate
    // - Метод отрабатывает корректно только в случае, если уже были совершены запросы
    // - Не стоит вызывать метод cancel до отправки запросов семейства send()
    func cancel(session: ProcessingSession)
}



//Основной класс-фасад, который необходимо проинициализовароть и удерживать
//Общение с VPS должно осуществляться через VPS.Session
//Основноная ответсвенность класса: оркестровка запросов, приходящих из Session, перенаправление их в фабрику по созданию собщений, передача
//данных сообщений в Transport и обратный маппинг ответных собщений в Transport в Session
final public class VPS {

    // MARK: - Properties

    private let configuration: Configuration
    private let messageFactory: MessageFactory
    private let transport: Transport
    private let queue = DispatchQueue(label: "ru.sberbank.voiceprocessing")

    /// Активные сессии, ключ – id сессии
    private(set) var sessions = [Int: ProcessingSession]()

    /// Есть особенность в логике отправки первого сообщения: оно специализированное
    /// для WebsocketTransport. Абстракция в настоящий момент позволяет вернуть
    /// из фабрики nil, тогда сообщение не будет отправлено
    private(set) var firstMessage = true

    // MARK: - Initializers

    /// Инициализатор сервиса по работе с Voice Processing Service API.
    ///
    /// - Parameters:
    ///        - configuration: Модель настроек сервиса.
    ///        - factory: Фабрика по созданию сообщений для работы сервиса.
    ///     - transport: Объект-траспортировщик сообщений(прим: WebSockets, TCP, UDP и т.д.).
    init(
        configuration: Configuration,
        factory: MessageFactory,
        transport: Transport
    ) {
        self.configuration = configuration
        self.messageFactory = factory
        self.transport = transport
        self.transport.delegate = self
    }

    /// Инициализатор серсива для работы по протоколу WebSockets.
    ///
    /// - Parameter configuration: Модель настроек-сервиса.
    public convenience init(configuration: Configuration) {
        let factory = MessageAbstractFactory(
            with: .protobuf,
            userId: configuration.userId,
            token: configuration.token,
            userChannel: configuration.userChannel
        )
        self.init(
            configuration: configuration,
            factory: factory,
            transport: WebsocketTransport(
                configuration: configuration,
                messageFactory: factory
            )
        )
    }
}

/// MARK: - <VPSProtocol>
extension VPS: VPSProtocol {

    func send(text: String, session: ProcessingSession) {
        queue.async { [weak self] in
            guard
                let self = self,
                session.state == .living
            else { return }

            self.trySendingSpecialMessages(for: session)
            self.sessions[session.id] = session

            let message = self.messageFactory.createMessage(with: text, messageId: session.id)
            self.transport.send(message: message)
        }
    }

    func send(voice: Data, session: ProcessingSession, last: Bool) {
        queue.async { [weak self] in
            guard
                let self = self,
                session.state == .living
            else { return }

            self.trySendingSpecialMessages(for: session)
            self.sessions[session.id] = session

            self.sendVoiceChunks(data: voice, session: session, last: last)
        }
    }

    func cancel(session: ProcessingSession) {
        queue.async { [weak self] in
            guard let self = self else { return }

            session.state = .finished
            session.resultQueue.sync { [weak session] in
                guard let session = session else { return }

                self.notifyDelegatesAboutSessionFinishing(for: session, wasCancelled: true)
                self.queue.async { [weak self] in
                    self?.sessions.removeValue(forKey: session.id)
                }
            }
        }
    }

    func notifyDelegatesAboutSessionFinishing(for session: ProcessingSession, wasCancelled: Bool) {
        session.resultQueue.async {
            session.recognitionSessionDelegate?.recognitionSessionDidFinish(
                session,
                canceled: wasCancelled
            )
            session.assistantDialogSessionDelegate?.assistantDialogSessionDidFinish(
                session,
                canceled: wasCancelled
            )
            session.vocalizationSessionDelegate?.vocalizationSessionDidFinish(
                session,
                canceled: wasCancelled
            )
        }
    }
}

private extension VPS {

    func trySendingSpecialMessages(for session: ProcessingSession) {
        sendFirstMessageIfNeeded()
        sendMutedSettingIfNeeded(for: session)
        sendEchoEnabledSettingIfNeeded(for: session)
    }

    func sendFirstMessageIfNeeded() {
        guard firstMessage else { return }
        let message = messageFactory.createInitialMessage(messageId: Random.int())
        transport.send(message: message)
        firstMessage = false
    }

    func sendMutedSettingIfNeeded(for session: ProcessingSession, force: Bool = false) {
        guard session.isMuted || force else { return }
        let message = messageFactory.createMessage(
            muted: true,
            messageId: session.id
        )
        transport.send(message: message)
    }

    func sendEchoEnabledSettingIfNeeded(for session: ProcessingSession) {
        guard session.isEchoEnabled else { return }
        let message = messageFactory.createMessage(
            isEchoEnabled: session.isEchoEnabled,
            messageId: Random.int()
        )
        transport.send(message: message)
    }

    func reset() {
        firstMessage = true
    }

    func sendVoiceChunks(
        data: Data,
        session: ProcessingSession,
        last: Bool,
        voiceChunkMaxSize: Int = 10000
    ) {
        var offset = 0

        while offset + voiceChunkMaxSize < data.count {
            let chunk = data[offset..<offset + voiceChunkMaxSize]
            let message = messageFactory.createMessage(
                with: chunk,
                messageId: session.id,
                last: false
            )
            transport.send(message: message)
            offset += voiceChunkMaxSize
        }
        if offset < data.count {
            let lastChunk = data[offset..<data.count]
            if !lastChunk.isEmpty {
                let message = messageFactory.createMessage(
                    with: lastChunk,
                    messageId: session.id,
                    last: last
                )
                transport.send(message: message)
            }
        }
    }
}

extension VPS: TransportDelegate {

    func estabilshedConnection() {}

    func lostConnection(with error: Error?) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.reset()
            self.sessions.values.forEach { self.fail(session: $0, with: Errors.connectionError) }
        }
    }

    func received(message: Message) {
        queue.async { [weak self] in
            guard let self = self else { return }
            guard let session = self.sessions[message.sessionId] else {
                return
            }
            guard session.state == .living else {
                return
            }

            if let error = message.error {
                self.fail(session: session, with: error)
            } else if let text = message.text {
                self.process(text: text, message: message, session: session)
            } else if let voice = message.data {
                self.process(voice: voice, message: message, session: session)
            } else if message.last {
                self.queue.async { [weak self] in
                    self?.tryToFinish(session: session, with: message)
                }
            }
        }
    }

    private func process(text: String, message: Message, session: ProcessingSession) {
        session.resultQueue.sync { [weak session] in
            guard let session = session else { return }
            // last - конец сообщения
            // Возможные значения для версии VPS
            // 1.1: ABK, CRT, GOOGLE
            // 1.2: STT
            if ["ABK", "CRT", "GOOGLE", "STT"].contains(message.additionalInfo) {
                session.recognitionSessionDelegate?.recognitionSession(
                    session,
                    didReceivePartialResult: text
                )
                if message.last {
                    session.recognitionSessionDelegate?.recognitionSessionDidFinish(
                        session,
                        canceled: false
                    )
                }
            } else {
                session.assistantDialogSessionDelegate?.assistantDialogSession(
                    session,
                    didReceiveText: text
                )
                if message.last {
                    session.assistantDialogSessionDelegate?.assistantDialogSessionDidFinish(
                        session,
                        canceled: false
                    )
                }
            }

            if session.isMuted {
                self.queue.async { [weak self] in
                    self?.tryToFinish(session: session, with: message)
                }
            }
        }
    }

    private func process(payload: String, message: Message, session: ProcessingSession) {
        session.resultQueue.sync { [weak session] in
            guard let session = session else { return }

            session.assistantDialogSessionDelegate?.assistantDialogSession(
                session,
                didReceivePayload: payload
            )
            if message.last {
                session.assistantDialogSessionDelegate?.assistantDialogSessionDidFinish(
                    session,
                    canceled: false
                )
            }

            if session.isMuted {
                self.queue.async { [weak self] in
                    self?.tryToFinish(session: session, with: message)
                }
            }
        }
    }

    private func process(voice: Data, message: Message, session: ProcessingSession) {
        session.resultQueue.sync { [weak session] in
            guard let session = session else { return }
            session.vocalizationSessionDelegate?.vocalizationSession(
                session,
                didReceivePartitialVoiceResut: voice
            )
            self.tryToFinish(session: session, with: message)
        }
    }

    private func fail(session: ProcessingSession, with error: Error) {
        session.state = .finished
        session.resultQueue.sync { [weak session] in
            guard let session = session else { return }
            notifyDelegates(for: session, aboutError: error)
            notifyDelegatesAboutSessionFinishing(for: session, wasCancelled: false)
            _ = self.queue.async { [weak self] in
                self?.sessions.removeValue(forKey: session.id)
            }
        }
    }

    private func notifyDelegates(for session: ProcessingSession, aboutError error: Error) {
        session.recognitionSessionDelegate?.recognitionSession(
            session,
            didReceiveError: error
        )
        session.assistantDialogSessionDelegate?.assistantDialogSession(
            session,
            didReceiveError: error
        )
        session.vocalizationSessionDelegate?.vocalizationSession(
            session,
            didReceiveError: error
        )
    }

    private func tryToFinish(session: ProcessingSession, with message: Message) {
        guard message.last else { return }
        session.state = .finished
        notifyDelegatesAboutSessionFinishing(for: session, wasCancelled: false)
        _ = self.queue.async { [weak self] in
            self?.sessions.removeValue(forKey: session.id)
        }
    }
}




extension VPS {
    
    enum Errors: Error {
        case connectionError
        case noSessionWithId
        case connnectionTimeout
        case unrecognizedMessage
        case sessionIsDead
        
        var localizedDescription: String {
            switch self {
            case .connectionError:
                return "Ошибка соединения внутри VPS. Все открытые сессии завершены."
            case .noSessionWithId:
                return "Нет сессии с указанным идентификатором."
            case .connnectionTimeout:
                return "Превышен допустимый таймаут на установление соединения. Все открытые сессии завершены."
            case .unrecognizedMessage:
                return "Получено неопознанное сообщение (нет ошибки, текста или голоса)."
            case .sessionIsDead:
                return "Сессия завершена. Необходимо создать новую."


            }
        }
    }
    
}
