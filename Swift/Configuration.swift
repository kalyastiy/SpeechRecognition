//
//  Configuration.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 21.10.2019.
//

import Foundation


extension VPS {
    
    //Конфигурация VPS
    public struct Configuration {
        
        // Конфигурация по умолчанию (в настоящий момент ипользуется голандский сервер)
        public static let defaultConf = Configuration(host: address, userId: UUID().uuidString)
        
        public typealias Host = String
        
        //Хост, с которым будет установливаться соединение
        public var host : Host
        
        //Таймаут соединения, задается в секундах
        public var connectionTimeout : TimeInterval = 10
        
        //Включить/выключить SSL Pinning
        public let sslPinningEnabled: Bool
        
        //Включить/выключить внутреннее логирование с выводом в консоль (передача данных)
        public var enableLogging: Bool = false
        
        
        //Уникальный идентификатор, зарезервирован на будущее
        public var token: String
        
        //Включить / выключить поддержку SSL Pining (whitelist)
        //При включении необходимо задавать свойство sslCertificate, в него передаются публичные ключи серверных сертификатов,
        //на основе которых клиент будет проверять валидность сервера
        public var sslEnable: Bool = true
        
        //Сертификаты для SSL Pinning (необходимо задать sslEnable = true) для их использования
        public var sslCertificates: [Certificate]?
        
        
        
        //Идентификатор по которому в будущем будет сохраняться контекст и история диалогов(не используется)
        public var userId: String
        
        public var userChannel = ""
        public var ttsEngine = ""
        public var sttEngine = ""
        public var dubbing = 1

        
        //Адрес стенда в Сигма, используется по умолчанию
        private static let address = "wss://vps-nlpp.apps.test-ose.sigma.sbrf.ru/ws/ask"
//        vps-nlpp-dev.apps.test-ose.sigma.sbrf.ru - DEV
//        vps-nlpp.apps.test-ose.sigma.sbrf.ru - IFT
//
//        /ws/ask – wss api
//        /handle – rest api

        
        
        //Автогенерируемый токен для всех конфигураций по умолчанию
        public static let defaultToken = Random.alphanumericString(length: 54)
    }
    
    
    public struct SSLConfiguration {
        
        public enum SSLConfirationError: Error {
            case certificateNotExist
        }
        
        public let enable: Bool
        
        public let certificates: [Certificate]?
        
        public init(enable: Bool = false, certificates: [Certificate]? = nil) throws {
            self.enable = enable
            self.certificates = certificates
            if enable && certificates == nil {
                throw SSLConfirationError.certificateNotExist
            }
        }
    }
}


extension VPS.Configuration {
    
    //КУРС == СБОЛ??
    
    // Инициализатор конфигурации сервиса по обработке голоса
    // URL для подключения, время по истечению которого будет сгенерирована ошибка соединения , флаг необходимости проверки соединения посредством SSL верификации,
    // логирования событий сервиса , идентификатор пользователя КУРС, уникальный аутентификационный токен сессии КУРС.
    
    public init (host: Host, connectionTimeInterval: TimeInterval = 10, sslPinningEnabled: Bool = true, enableLogging: Bool = false, userId: String,
                 token: String = defaultToken, userChannel: String = "AFINA", ttsEngine: String = "default", sttEngine: String = "default", dubbing: Int = 1) {
        
        self.host = host
        self.connectionTimeout = connectionTimeInterval
        self.sslPinningEnabled = sslPinningEnabled
        self.enableLogging = enableLogging
        self.userId = userId
        self.token = token
        
        self.userChannel = userChannel
        self.ttsEngine = ttsEngine
        self.sttEngine = sttEngine
        self.dubbing = dubbing

    }
}


final class ChatConfig: NSObject  {
        
    public var userId: String
    public var userChannel = ""
    public var ttsEngine = ""
    public var sttEngine = ""
    public var dubbing = 1
    
    @objc
    public init(userId: String, userChannel: String, ttsEngine: String, sttEngine: String, dubbing: Int) {
        self.userId = userId
        self.userChannel = userChannel
        self.ttsEngine = ttsEngine
        self.sttEngine = sttEngine
        self.dubbing = dubbing
    }


}





struct Random {
    
    private init() {}
    
    //Метод генерирует случайное значение типа Int (из за возможной поддержки 32-х битных арихитектур используется Int32,
    //который на выходе преобразуется к Int)
    static func int() -> Int {
        return Int(Int32.random(in: 1..<INT32_MAX))
    }
    
    //Генерируе строку заданной длины случайных символово английского алфавита(строчные и заглавные) и цифр
    static func alphanumericString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0...length - 1).map {_ in letters.randomElement()!})
    }
}
