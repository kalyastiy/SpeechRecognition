//
//  AssistantController.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 22.10.2019.
//

import Foundation

///
/// Делегат событий от сервиса сообщений о полученных данных и возникших ошибках.
///
protocol AssistantControllerDelegate: AnyObject {

    // MARK: - Methods

    func didReceivedMessage(text: String)
    func didReceivedMessage(payload: String)
    func didReceivedMessage(transcript: String)
    func didFinishTranscription()
    func didReceivedError(error: Error)
}

//
// Протокол по взаимодействию с внешним сервисом отправки/получения сообщений.
//
protocol AssistantControllerProtocol {

    // MARK: - Methods

    func sendMessage(text: String)
    func startVoiceTranscription()
    func stopVoiceTranscription()
    func setDelegate(_ delegate: AssistantControllerDelegate)
}

//
// Сервис по отправке сообщений с использованием VoiceProcessingServiceSDK.
//
public final class AssistantController {

    // MARK: - Properties

    weak var delegate: AssistantControllerDelegate?

    private var voiceProcessingService: VPS
    private var activeProcessingSession: SessionProtocol?
    private lazy var speechVocalizer: SBSpeechVocalizer = .init()

    var speechRecognizer: SpeechRecognizer?

    var isSilentMode = false

    // MARK: - Initializers

    public init(processingService: VPS) {
        self.voiceProcessingService = processingService
    }
}

// MARK: - <MessageService>
extension AssistantController: AssistantControllerProtocol {

    // MARK: - Methods

    func sendMessage(text: String) {
        finishLastActiveSession()
        let newActiveSession = ProcessingSession(service: self.voiceProcessingService)
        activeProcessingSession = newActiveSession
        newActiveSession.assistantDialogSessionDelegate = self
        do {
            try initializeVocalizerIfNeeded(for: newActiveSession)
        } catch {
            delegate?.didReceivedError(error: error)
        }
        newActiveSession.send(text: text)
    }

    func startVoiceTranscription() {
        finishLastActiveSession()
        let newActiveSession = ProcessingSession(service: self.voiceProcessingService)

        activeProcessingSession = newActiveSession
        newActiveSession.assistantDialogSessionDelegate = self
        do {
            try initializeRecognizer(for: newActiveSession)
            try initializeVocalizerIfNeeded(for: newActiveSession)
        } catch {
            delegate?.didReceivedError(error: error)
        }
    }

    private func initializeVocalizerIfNeeded(for session: ProcessingSession) throws {
        guard !isSilentMode else { return }
        speechVocalizer.processingSession = session
    }

    private func initializeRecognizer(for session: ProcessingSession) throws {
        var speechRecognizer = try SBSpeechRecognizer.recognizer(with: session, chunkDuration: 0)
        speechRecognizer.startRecording()
        speechRecognizer.delegate = self
        self.speechRecognizer = speechRecognizer
    }

    func stopVoiceTranscription() {
        speechRecognizer?.stopRecording()
    }

    private func finishLastActiveSession() {
        activeProcessingSession?.cancel()
        activeProcessingSession = nil
    }

    func setDelegate(_ delegate: AssistantControllerDelegate) {
        self.delegate = delegate
    }
}

/// MARK: - <SpeechRecognizerDelegate>
extension AssistantController: SpeechRecognizerDelegate {
    public func recognitionSessionDidFinishedRecivedVoice(_ last: Bool, voice: Data) {
        
    }
    

    // MARK: - Methods

    public func recognizerDidStartRecording(_ recognizer: SpeechRecognizer) { }

    public func recognizerDidFinishRecording(_ recognizer: SpeechRecognizer) { }

    public func recognizer(_ recognizer: SpeechRecognizer, didUpdatePower power: Float) { }

    public func recognizer(_ recognizer: SpeechRecognizer, didReceiveResult result: String) {
        delegate?.didReceivedMessage(transcript: result)
    }

    public func recognizerDidFinishRecognition(_ recognizer: SpeechRecognizer) {
        speechRecognizer = nil
        delegate?.didFinishTranscription()
    }

    public func recognizer(_ recognizer: SpeechRecognizer, didFailWithError error: Error) { }
}

/// MARK: - <AssistantDialogSessionDelegate>
extension AssistantController: AssistantDialogSessionDelegate {

    // MARK: - Methods

    public func assistantDialogSession(_ session: SessionProtocol, didReceiveText text: String) {
        let normalizedMessage = normalizeText(text)
        delegate?.didReceivedMessage(text: normalizedMessage)
    }

    public func assistantDialogSession(_ session: SessionProtocol, didReceivePayload payload: String) {
        let normalizedMessage = normalizeText(payload)
        delegate?.didReceivedMessage(payload: normalizedMessage)
    }

    func normalizeText(_ text: String) -> String {
        return text
            .removeHTMLEntities()
            .unescapeSpecialCharacters()
    }

    public func assistantDialogSessionDidFinish(_ session: SessionProtocol, canceled: Bool) { }

    public func assistantDialogSession(_ session: SessionProtocol, didReceiveError error: Error) {
        delegate?.didReceivedError(error: error)
    }
}
