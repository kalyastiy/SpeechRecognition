//
//  SessionProtocol.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 21.10.2019.
//

import Foundation


/// Протокол VPS.Session, @see VPS.Session.
public protocol SessionProtocol: AnyObject {

    /// Выключение озвучки ответа.
    var isMuted: Bool { get set }

    /// Включить обратное озвучивание отправленного текста.
    var isEchoEnabled: Bool { get set }

    var recognitionSessionDelegate: RecognitionSessionDelegate? { get set }
    var assistantDialogSessionDelegate: AssistantDialogSessionDelegate? { get set }
    var vocalizationSessionDelegate: VocalizationSessionDelegate? { get set }

    /// Передать текст на обработку. Можно вызвать только один раз,
    /// после получения ответа сессия завершится.
    func send(text: String)

    /// Передать голос на обработку. Можно вызывать много раз,
    /// для завершения передачи голоса необходимо выставить флаг last.
    /// После получения ответа сессия завершится.
    func send(voice: Data, last: Bool)

    /// Завершить текущую сессию с посылкой отменяющего запроса.
    /// - note: В настоящий момент не реализовано.
    func cancel()

    /// DispatchQueue, в которую будет возвращать исполнение delegate.
    /// - note: По умолчанию используется DispatchQueue.main.
    var resultQueue: DispatchQueue { get set }
}

///
/// Делегат сессии по разпознаванию голоса. Позволяет получать промежуточный результат
/// распознавания в зависимости от принятых голосовых фрагментов.
///
public protocol RecognitionSessionDelegate: AnyObject {

    // MARK: - Methods

    /// Вызывается при получении надиктованного распознанного текста.
    /// - note: Каждый новый вызов присылает полный текст.
    ///
    /// - Parameters:
    ///   - request: Сессия, инициирующая событие.
    ///   - text: Распознанный текст.
    func recognitionSession( _ session: SessionProtocol, didReceivePartialResult result: String)

    /// Вызывается при завершении сессии.
    /// Флаг cancelled информирует о том произошло ли завершении сессии из-за отмены.
    ///
    /// - Parameters:
    ///   - request: Сессия, инициирующая событие.
    ///   - wasCancelled: Флаг завершения.
    func recognitionSessionDidFinish(_ session: SessionProtocol, canceled: Bool)

    /// Вызывается при получении ошибки в рамках сессии
    /// - note: После вызова `receivedError` вызовется делегатный метод
    /// `didFinish` в том же цикле `Runloop`.
    ///
    /// - Parameters:
    ///   - request: Сессия, инициирующая событие.
    ///   - error: Сгенерированная ошибка.
    func recognitionSession(_ session: SessionProtocol, didReceiveError error: Error)
}

///
/// Делегат получения текстовых ответов от виртуального помощника.
///
public protocol AssistantDialogSessionDelegate: AnyObject {

    // MARK: - Methods

    /// Вызывается при получении текста ответа
    ///
    /// - Parameters:
    ///   - request: Сессия, инициирующая событие.
    ///   - text: Текст ответа.
    func assistantDialogSession(_ session: SessionProtocol, didReceiveText text: String)

    /// Вызывается при получении сервисного сообщения.
    ///
    /// - Parameters:
    ///   - request: Сессия, инициирующая событие.
    ///   - text: Полезная информация в виде строки. Внутри может быть что угодно в виде JSON.
    func assistantDialogSession(_ session: SessionProtocol, didReceivePayload payload: String)

    /// Вызывается при завершении сессии.
    /// Флаг cancelled информирует о том произошло ли завершении сессии из-за отмены.
    ///
    /// - Parameters:
    ///   - request: Сессия, инициирующая событие.
    ///   - wasCancelled: Флаг завершения.
    func assistantDialogSessionDidFinish(_ session: SessionProtocol, canceled: Bool)

    /// Вызывается при получении ошибки в рамках сессии
    /// - note: После вызова `receivedError` вызовется делегатный метод
    /// `didFinish` в том же цикле `Runloop`.
    ///
    /// - Parameters:
    ///   - request: Сессия, инициирующая событие.
    ///   - error: Сгенерированная ошибка.
    func assistantDialogSession(_ session: SessionProtocol, didReceiveError error: Error)
}

///
/// Делегат процесса распознавания речи.
/// Получает новые фрагменты синтезированной речи в сыром виде.
///
public protocol VocalizationSessionDelegate: AnyObject {

    // MARK: - Methods

    /// Вызывается при получении голосового ответа
    ///
    /// - Parameters:
    ///   - request: Сессия, инициирующая событие.
    ///   - data: Голосовые данные в формате WAV PCM 16Bit, 22 kHz.
    func vocalizationSession(_ session: SessionProtocol, didReceivePartitialVoiceResut data: Data)

    /// Вызывается при завершении сессии.
    /// Флаг cancelled информирует о том произошло ли завершении сессии из-за отмены.
    ///
    /// - Parameters:
    ///   - request: Сессия, инициирующая событие.
    ///   - wasCancelled: Флаг завершения.
    func vocalizationSessionDidFinish(_ session: SessionProtocol, canceled: Bool)

    /// Вызывается при получении ошибки в рамках сессии
    /// - note: После вызова `receivedError` вызовется делегатный метод
    /// `didFinish` в том же цикле `Runloop`.
    ///
    /// - Parameters:
    ///   - request: Сессия, инициирующая событие.
    ///   - error: Сгенерированная ошибка.
    func vocalizationSession(_ session: SessionProtocol, didReceiveError error: Error)
}

