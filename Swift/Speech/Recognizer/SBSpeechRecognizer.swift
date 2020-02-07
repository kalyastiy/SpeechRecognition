//
//  SBSpeechRecognizer.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 22.10.2019.
//

import Foundation
import AVFoundation

//Обьект-распознования, использующий внутребанковский механиз преобразования речи в текст.
//Important: При запуске обьекта класса SBSpeechRecognizer с аудиоисточником по-умолчанию
//или любым другим источником, который использует стандартный вход устройства, необходимо
//правильно настроить аудиосесию прлиожения и поставить категорию не ниже ".record"

public final class SBSpeechRecognizer: SpeechRecognizer {
    
    public weak var delegate: SpeechRecognizerDelegate?
    
    private var audioSource: AudioSource
    private var processingSession: SessionProtocol
    
    //Инициализация обьекта для распознавания речи с использованием источника
    //звука и сессии распознавания для VPS-сервиса
    //-audioSource: Источник звука для распознования речи
    //-processingSession: Сессия VPS, в рамках которой будет происходить процесс распознования речи
    init(audioSource: AudioSource, processingSession: SessionProtocol) {
        self.audioSource = audioSource
        self.processingSession = processingSession
        self.audioSource.delegate = self
        self.processingSession.recognitionSessionDelegate = self
    }
    
    public func startRecording() {
//        processingSession.isMuted = true
//        processingSession.isEisEnable = false
        audioSource.start()
    }
    
    public func stopRecording() {
        audioSource.stop()
    }
    
    public func cancelRecording() {
        audioSource.cancel()
        processingSession.cancel()
    }
}


extension SBSpeechRecognizer: AudioSourceDelegate {
    
    public func audioSourceDidStartListening(_ audioSource: AudioSource) {
        delegate?.recognizerDidStartRecording(self)
    }
    
    public func audioSourceDidStopListening(_ audioSource: AudioSource) {
        sendLastChunkToRecognitionService()
        delegate?.recognizerDidFinishRecording(self)
    }
    
    private func sendLastChunkToRecognitionService() {
        //Посылаем пакет с пустой последовательностью байт
        //для уведомления о завершении записии
        processingSession.send(voice: Data(), last: true)
    }
    
    public func audioSource(_ audioSource: AudioSource, didReceiveData data: AVAudioPCMBuffer) {
        let convertedData = Data(buffer: data)
        sendChunkToRecognitionService(convertedData)
    }
    
    private func sendChunkToRecognitionService(_ chunk: Data) {
        processingSession.send(voice: chunk, last: false)
    }
    
    public func audioSource(_ audioSource: AudioSource, didUpdatePower power: Float) {
        delegate?.recognizer(self, didUpdatePower: power)
    }
    
    public func audioSource(_ audioSource: AudioSource, didFailWithError error: Error) {
//        processingSession.cancel()
        delegate?.recognizer(self, didFailWithError: error)
    }
}


extension SBSpeechRecognizer: RecognitionSessionDelegate {
    
    public func recognitionSession(_ session: SessionProtocol, didReceivePartialResult result: String) {
        delegate?.recognizer(self, didReceiveResult: result)
    }
    
    public func recognitionSessionDidFinish(_ session: SessionProtocol, canceled cancelled: Bool) {
        if cancelled { audioSource.cancel() }
        delegate?.recognizerDidFinishRecognition(self)
    }
    
    public func recognitionSession(_ session: SessionProtocol, didReceiveError error: Error) {
        audioSource.cancel()
        delegate?.recognizer(self, didFailWithError: error)
    }
    
    public func recognitionSessionDidFinishedRecivedVoice(_ last: Bool, voice: Data) {
        delegate?.recognitionSessionDidFinishedRecivedVoice(last, voice: voice)
    }
}



// Creation
extension SBSpeechRecognizer {
    
    public enum SBSpeechRecognizerError: Swift.Error {
        case incorrectOutputFormat
    }
    
    //Фабричный метод для создания обьекта распознования с возможностью настройки аудио источника, формата звкуковых фрагментов для обработки
    //на сервере и длительностью этих звкуковых фрагментов
    //-session: Сессия VPS в рамках которой будет осуществлять распознавание речи
    //-format: Аудиофрмат сообщений серверу для распознавания речи (VPS поддерживает только определенные форматы голосовых пакетов)
    //-chunkDuration: Длительность голосовых фрагментов для отправки
    //-Throws: Ошибки инициализации внутреннего модуля распознования
    //-Returns: Проинициализированный обьект для распознования речи
    static func recognizer(with session: ProcessingSession, format: AVAudioFormat, chunkDuration: TimeInterval) throws -> SpeechRecognizer {
        let manualSource = ManualAudioSource()
        let convertedSource = try ConvertableAudioSource(manualSource, inputuFormat: manualSource.inputFormat, outputFormat: format)
//        let chunkedSource = ChunkedAudioSource(convertedSource, perFrameInterval: chunkDuration)
        return SBSpeechRecognizer(audioSource: convertedSource, processingSession: session)
    }
    
    //Фабричный метод для создания обьекта распознавания, сконфигурировнанного под внутрибанковский VPS сервиса с возможностью
    //настройки аудио источника и длительности этих звуковых фрагментов
    //-session: Сессия VPS в рамках которой будет осуществлять распознавание речи.
    //-chunkDuration: Длительность голосовых фрагментов для отправки
    //-Throw: Ошибки инициализации внутреннего модуля распознования
    //-returns: Проинициализоварованный обьект для распознования речи, позволяющий работать с внутрибанковским VPS
    public static func recognizer(with session: ProcessingSession, chunkDuration: TimeInterval) throws -> SpeechRecognizer { //WAV PCM Mono 16Bit, 16kHz
        let formatSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: Float(16000),
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 16,
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
        ]
        guard let format = AVAudioFormat(settings: formatSettings) else {
            throw SBSpeechRecognizerError.incorrectOutputFormat
        }
        return try recognizer(with: session, format: format, chunkDuration: chunkDuration)
    }
        
    
}







//Расширения по взаимодействию Data с AVAudioPCMBuffer
//Позволяет конвертировать одно в другие и обратно
extension Data {
    
    //Создание Data на основе аудиобуффера
    //-budder: Аудиобуффер для конвертации
    init(buffer: AVAudioPCMBuffer) {
        let audioBuffer = buffer.audioBufferList.pointee.mBuffers
        self.init(bytes: audioBuffer.mData!, count: Int(audioBuffer.mDataByteSize))
    }
    
    //Преобразование Data к AVAudioPCMBuffer, если такое возможно
    //-format: Предполагаемый формат аудиобуфера
    //-returnts: Сгенерированный на основе Data аудиобуффер
    func makePCMBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let streamDesc = format.streamDescription.pointee
        let frameCapacity = UInt32(count) / streamDesc.mBytesPerFrame
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity) else { return nil }
        
        buffer.frameLength = buffer.frameCapacity
        let audioBuffer = buffer.audioBufferList.pointee.mBuffers
        
        withUnsafeBytes { addr in
            audioBuffer.mData?.copyMemory(from: addr, byteCount: Int(audioBuffer.mDataByteSize))
        }
        return buffer
    }
}
