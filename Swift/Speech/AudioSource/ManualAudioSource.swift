//
//  ManualAudioSource.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 22.10.2019.
//

import Foundation
import AVFoundation

//Источник аудиопотока с основного входа устройства, работающий на AudioEngine
//Important: При запуске обьекта класса "YSKOnlineRecognizer" с аудиоисточником по умолчанию или любым другим источником, который использует стартный
//вход устройства, необходимо правильно настроить аудиосессию приложения
//Note: Класс-помощник для аккамулирования логики обработки звука

public class ManualAudioSource {
    
    //-cannotComputePowerFromBuffer: Ошибка получения текущего уровня громкости сигнала из полученного буффера
    enum AudioSourceError: Swift.Error {
        case cannotComputePowerFromBuffer(AVAudioPCMBuffer)
    }
    
    private let deviceMicrophoneInputBus = 0
    
    //Делегат событий набюдателя за звуком с микрофона
    public final weak var delegate: AudioSourceDelegate?
    
    //Запущен ли мониторинг звука со стандартного аудиовхода устройства
    public final var isRunning: Bool {
        return audioEngine.isRunning
    }
    
    //Формат аудиопотока со стандартного входа устройства
    final var inputFormat: AVAudioFormat {
        return inputNode.outputFormat(forBus: deviceMicrophoneInputBus)
    }
    
    private(set) final var audioEngine: AudioEngine
    private let inputNode: AudioInputNode
    
    //Инициализация слушателя входного сигнала с микрофона устройства
    //Данные с источника звука будут поступать в исходином формате без какой-либо конвертации
    //Important: Необходимо разрешение от пользователя на использование микрофона
    //-audioEngine: AudioEngine для получения звуковых данных.
    //-inputNode: Узел для получения звуковых данных.
    //-timeout: Время ожидания звукового сигнала.
    init(audioEngine: AudioEngine, inputNode: AudioInputNode) {
        self.audioEngine = audioEngine
        self.inputNode = inputNode
    }
    
    //Инициализация слушателя входного сигнала с микрофона устройства.
    //Данные с источника звука будут поступать в исходином формате без какой-либо конвертации
    //Important: Необходимо разрешение от пользователя на использование микрофона
    public convenience init(audioEngine: AVAudioEngine = AVAudioEngine()) {
        self.init(audioEngine: audioEngine, inputNode: audioEngine.inputNode)
    }
    
    func computePower(from buffer: AVAudioPCMBuffer) -> Float? {
        return AudioPowerCalculator(from: buffer)?.value
    }
}


extension ManualAudioSource: AudioSource {
    
    public final func start() {
        do {
            guard !isRunning else { return }
            configureAudioInputObservation()
            try audioEngine.start()
            delegate?.audioSourceDidStartListening(self)
        } catch {
            delegate?.audioSource(self, didFailWithError: error)
        }
    }
    
    
    private final func configureAudioInputObservation() {
        let recordingFormat = inputFormat
        inputNode.installTap(onBus: deviceMicrophoneInputBus, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer: AVAudioPCMBuffer, _) in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.updateSourcePower(with: buffer)
                self.delegate?.audioSource(self, didReceiveData: buffer)
            }
        }
    }
    
    private final func updateSourcePower(with buffer: AVAudioPCMBuffer) {
        guard let power = computePower(from: buffer) else {
            delegate?.audioSource(self, didFailWithError: AudioSourceError.cannotComputePowerFromBuffer(buffer))
            cancel()
            return
        }
        self.delegate?.audioSource(self, didUpdatePower: power)
    }
    
    public final func stop() {
        cancel()
    }
    
    public final func cancel() {
        guard isRunning else { return }
        audioEngine.stop()
        inputNode.removeTap(onBus: deviceMicrophoneInputBus)
        delegate?.audioSourceDidStopListening(self)
    }
}




//Обьект-обертка для получения значения уровня громкости в относительную величину в диапозоне [0...1].
struct AudioPowerCalculator {
    
    private(set) var value: Float = 0.0
    
    //Инициализатор обертки для получения уровня звука с микрофона
    //-buffer: Аудиобуффер полученный с микрофона устройства
    init?(from buffer: AVAudioPCMBuffer) {
        guard let channelDataValueArray = retrieveAnArrayOfFloats(from: buffer) else { return nil }
        let rms = calculateRootMeanSquare(from: channelDataValueArray, by: buffer.frameLength)
        
        let avgPower = convertRootMeanSquareToDecibels(rms)
        let normalizedPower = self.normalize(power: avgPower)
        self.value = normalizedPower
    }
    
    
    private func retrieveAnArrayOfFloats(from buffer: AVAudioPCMBuffer) -> [Float]? {
        guard let channelData = buffer.floatChannelData else { return nil }
        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride).map { channelDataValue[$0] }
        return channelDataValueArray

    }
    
    private func calculateRootMeanSquare(from dataArray: [Float], by frameLenght: AVAudioFrameCount) -> Float {
        let dataArrayWithSquareValues = dataArray.map { $0 * $0 }
        return sqrt(dataArrayWithSquareValues.reduce(0, +) / Float(frameLenght))
    }
    
    private func convertRootMeanSquareToDecibels(_ rms: Float) -> Float {
        return 20 * log10(rms)
    }
    
    private func normalize(power: Float) -> Float {
        guard power.isFinite else { return 0.0 }
        
        let minDb: Float = -80.0
        if power < minDb {
            return 0.0
        } else if power >= 1.0 {
            return 1.0
        } else {
            return (abs(minDb) - abs(power)) / abs(minDb)
        }
    }
}





//Протокол дублика
//является дублирующим протоколом для возмоности тестирования кода
protocol AudioEngine {
    
    var isRunning: Bool { get }
    
    func start() throws
    func stop()
}

//Соотвествие реального класса протоколу для защиты от изменений в конктае модуля.
//Note: В случае изменения интерфейса, компилятор выдаст ошибку на этом месте.
extension AVAudioEngine: AudioEngine { }

//Протокол дублика
//является дублирующим протоколом для возмоности тестирования кода
protocol AudioInputNode {
    
    func outputFormat(forBus bus: AVAudioNodeBus) -> AVAudioFormat
    func installTap(onBus bus: AVAudioNodeBus, bufferSize: AVAudioFrameCount, format: AVAudioFormat?, block tapBlock: @escaping AVAudioNodeTapBlock)
    func removeTap(onBus bus: AVAudioNodeBus)
}

//Соотвествие реального класса протоколу для защиты от изменений в конктае модуля.
//Note: В случае изменения интерфейса, компилятор выдаст ошибку на этом месте.
extension AVAudioInputNode: AudioInputNode { }

