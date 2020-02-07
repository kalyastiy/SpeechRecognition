//
//  ConvertableAudioSource.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 22.10.2019.
//

import Foundation
import AVFoundation

//Декоратор надо источником аудиопотока, позволяющиц преобразовываать полученный аудиобуффер к требуемуому формату.

final class ConvertableAudioSource {
    
    weak var delegate: AudioSourceDelegate? {
        didSet {
            audioSource.delegate = (self.delegate != nil) ? self : nil
        }
    }
    
    private var audioSource: AudioSource
    private var converter: AudioFormatConverter

    
    //Инициализация декоратора для конвертации потока аудиоданных с помощью заданного конвертера
    //-audiosource: Декорируемый источник аудио.
    //-converter: Конвертер для преобразования аудиоданных.
    //-returnts: Задекорированный источник аудиоданных.
    
    init(_ audioSource: AudioSource, converter: AudioFormatConverter) {
        self.audioSource = audioSource
        self.converter = converter
    }
    
    //Инициализация декоратора для конвертации потока аудиоданных из исходного формата в заданный
    //-audioSource: Декорируемый источник аудио
    //-inputuFormat: Исходиный формат для конвертации.
    //-outputFormat: Результирующий формат для конвертации
    //-Throws: Ошибки создания аудиоконвертера.
    //-Returnts: Задекорированный источник аудиоданных
    
    convenience init (_ audioSource: AudioSource, inputuFormat: AVAudioFormat, outputFormat: AVAudioFormat) throws {
        let converter = try AudioSourceFormatConverter(format: .init(from: inputuFormat, to: outputFormat))
        self.init(audioSource, converter: converter)
    }
}


extension ConvertableAudioSource: AudioSourceDelegate {
    
    func audioSourceDidStartListening(_ audioSource: AudioSource) {
        delegate?.audioSourceDidStartListening(audioSource)
    }
    
    func audioSourceDidStopListening(_ audioSource: AudioSource) {
        delegate?.audioSourceDidStopListening(audioSource)
    }
    
    func audioSource(_ audioSource: AudioSource, didReceiveData data: AVAudioPCMBuffer) {
        do {
            let dispatchingBuffer = try converter.convert(buffer: data)
            delegate?.audioSource(audioSource, didReceiveData: dispatchingBuffer)
        } catch {
            cancel()
            delegate?.audioSource(audioSource, didFailWithError: error)
        }
    }
    
    func audioSource(_ audioSource: AudioSource, didUpdatePower power: Float) {
        delegate?.audioSource(audioSource, didUpdatePower: power)
    }
    
    func audioSource(_ audioSource: AudioSource, didFailWithError error: Error) {
        delegate?.audioSource(audioSource, didFailWithError: error)
    }
}


extension ConvertableAudioSource: AudioSource {
    
    var isRunning: Bool {
        return audioSource.isRunning
    }
    
    func start() {
        audioSource.start()
    }
    
    func stop() {
        audioSource.stop()
    }
    
    func cancel() {
        audioSource.cancel()
    }
}
