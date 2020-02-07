//
//  ProcessingSession.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 21.10.2019.
//

import Foundation

final public class ProcessingSession {
    
    //Класс для созднания обращения (установки сесси) к VPS, необходимо создавать каждый раз новую сессию для нового обращения
    //Создание сессии не пересоздает весь стек (VPS, Transport, MessageFactory)
    //Сессия обладает следующим жизненным циклом:
    // 1. Cессия создается и ее state становится равным .living
    // 2. Инициализируется запрос (передача текста или голоса)
    // 3. Первым сообщением передаеются настройки (например, включить ли озвучку)
    // 4. Сессия обращается к VPS для оркестровки запроса и получения ответа
    // 5. На текстовый запрос возвращается текст и потомк голоса (WAV PCM 16Bit, 22kHz)
    // 6. При отправки голоса будет возвращаться надиктованный распознанный текст
    // 7. При отправки голоса необходимо 1 раз передать isLast , после этого на backend VPS запуситтсяь процесс распознания речи и вернется ответ в виде
    // текста и потока голоса
    // 8. Сессия завершится
    
    // При попытки отправить сообщение по завершенной сессии - вернется ошибка
    // При попытки отправить сообщение по отмененной сесси -  вернется ошибка
    // - note: Созданные обьекты Session удерживаются внутри VPS до тех пор пока сессия активна
    
    public weak var recognitionSessionDelegate: RecognitionSessionDelegate?
    public weak var assistantDialogSessionDelegate: AssistantDialogSessionDelegate?
    public weak var vocalizationSessionDelegate: VocalizationSessionDelegate?
    
    
    public var isMuted = false//true
    public var isEisEnable = true


    public var resultQueue = DispatchQueue.main
    
    //Конструктор внутри модуля, должен использоваться для тестов (т.к нужно уметь )
    public init(service: VPS, sessionId: Int) {
        self.service = service
        self.id = sessionId
    }
    
    public convenience init (service: VPS) {
        self.init(service: service, sessionId: Random.int())
    }
    
    //Состояние сессии
    //living устанавливается при создании сесси, fininshed устанавливает VPS после завершения
    var state: State = .living
    
    let id: Int
    
    //Состояние сессии
    // - living сессия активна
    // - finished сессия заверешена
    enum State {
        case living
        case finished
    }
    
    // Сервис VPS
    private var service: VPS
    public var isEchoEnabled: Bool = false
}


extension ProcessingSession: SessionProtocol {
    
    public func send(text: String) {
        guard state == .living else { return }
        service.send(text: text, session: self)
    }
    
    public func send(voice: Data, last: Bool) {
        guard state == .living else { return }
        service.send(voice: voice, session: self, last: last)
    }
    
    public func cancel() {
        guard state == .living else { return }
        service.cancel(session: self)
    }

}
