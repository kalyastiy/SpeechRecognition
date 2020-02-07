//
//  MessageFactory.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 21.10.2019.
//

import Foundation

/// Протокол фабрики по созданию сообщений (Message) для различных логических операций
/// - note: Протокол создаёт абстракцию и изолирует код от работы с фабрикой конкретного
/// прикладного протокола передачи данных
protocol MessageFactory {

    /// Метод по созданию первого сообщения
    /// - note: В случае изменения конкретной реализации и необходимости отказаться
    /// от логики работы с первым сообщений, достаточно будет вернуть nil
    ///
    /// - Parameter messageId: Идентификатор сообщения
    /// - Returns: Сообщение
    func createInitialMessage(messageId: Int) -> Message

    /// Метод по созданию текстового сообщения
    ///
    /// - Parameters:
    ///   - text: Текст сообщения
    ///   - messageId: Идентификатор сообщения
    /// - Returns: Сообщение
    func createMessage(with text: String, messageId: Int) -> Message

    /// Метод по созданию голосового сообщения
    /// Метод можно вызывать неоднократно в рамках активной сессии
    /// для передачи голосового потока небольшими порциями.
    /// Для завершения передачи необходимо передать last = true.
    /// Метод внутри себя разделяет voice на меньшие по размеру
    /// chunk-и, чтобы они не превышали установленный сервером лимит
    ///
    /// - Parameters:
    ///   - voice: Набор байт голоса
    ///   - messageId: Идентификатор сообщения
    ///   - last: Флаг последнего сообщения
    /// - Returns: Сообщение
    func createMessage(with voice: Data, messageId: Int, last: Bool) -> Message

    /// Метод по созданию сообщения из сериализованных данных
    ///
    /// - Parameter data: Сериализованное сообщение
    /// - Returns: Сообщение
    /// - Throws: Ошибка создания сообщения (в случае ошибки сериализации)
    func createMessage(data: Data) throws -> Message

    /// Метод по созданию специального сообщения, выключающего или включающего
    /// озвучку ответа
    ///
    /// - Parameters:
    ///   - muted: Включить или выключить озвучку ответа (true – выключить)
    ///   - messageId: Идентификатор сообщения
    /// - Returns: Сообщение
    func createMessage(muted: Bool, messageId: Int) -> Message

    /// Метод по созданию специального сообщения, выключающего или включающего
    /// работу с сервисом EIS (прокси перед NLP-платформой)
    ///
    /// - Parameters:
    ///   - isEchoEnabled: Включить режим озвучивания отправленного текста.
    ///   - messageId: Идентификатор сообщения
    /// - Returns: Сообщения
    func createMessage(isEchoEnabled: Bool, messageId: Int) -> Message
}

/// Абстракная фабрика по созданию Message, абстрагирует от конкретной фабрики,
/// создающей сообщения, использующие конкретный протокол сериализации / десериализации
struct MessageAbstractFactory {

    enum MessageType {
        case protobuf
    }

    private let concreteFactory: MessageFactory

    init(with type: MessageType, userId: String, token: String, userChannel: String) {
        switch type {
        case .protobuf:
            concreteFactory = ProtobufMessageFactory(
                userId: userId,
                token: token,
                userChannel: userChannel,
                ttsEngine: "default",
                sttEngine: "abc_sd_internal_general_stt",
                dubbing: 1
            )
        }
    }
}

extension MessageAbstractFactory: MessageFactory {

    func createMessage(with voice: Data, messageId: Int, last: Bool) -> Message {
        return concreteFactory.createMessage(with: voice, messageId: messageId, last: last)
    }

    func createInitialMessage(messageId: Int) -> Message {
        return concreteFactory.createInitialMessage(messageId: messageId)
    }

    func createMessage(with text: String, messageId: Int) -> Message {
        return concreteFactory.createMessage(with: text, messageId: messageId)
    }

    func createMessage(data: Data) throws -> Message {
        return try concreteFactory.createMessage(data: data)
    }

    func createMessage(muted: Bool, messageId: Int) -> Message {
        return concreteFactory.createMessage(muted: muted, messageId: messageId)
    }

    func createMessage(isEchoEnabled: Bool, messageId: Int) -> Message {
        return concreteFactory.createMessage(isEchoEnabled: isEchoEnabled, messageId: messageId)
    }
}




//Протокол бинарной сериализуемости

protocol BinarySerializable {
    
    //Метод сериализации
    //Returns: последовательность байт
    //Throws: Ошибка в случае невозможсности сериализации
    func  binaryData() throws -> Data
    
}

//Протокол бинарной десериализуемости

protocol BinaryDeserializable {
    
    //Конструктор-десериализотор
    //Parameters data: Исходные байты сообщения
    //Throws : Ошибка в случае невозможности десерилиазации
    init(binaryData: Data) throws
}


protocol Message: BinarySerializable & BinaryDeserializable {
    
    // Текст сообщения
    var text: String? { get }
    
    //Бинарные данные внутри сообщения
    var data: Data? { get }
    
    //Ошибка внутри сообщения
    var error: Error? { get }
    
    //Идентификатор сессии в рамках которой было отправлено сообщение
    // - note: Используется уровнем выше для осуществления маппинга Message в Session
    var sessionId: Int { get }
    
    //Флаг, показывающий что сообщение последнее
    // - note: Используется уровнем выше для понимания необходимости завершить Session
    var last: Bool { get }
    
    //Дополнительная информация от отвечающей системы
    // - note: Используется сторонними системами для определения последующего шага процесса
    var additionalInfo: String? { get }
    
    //Метод, возвращающий описание реального сообщения. Смысл такой же как description или debugDescription
    //у классов , унаследованных от SwiftObject
    func description() -> String
}
