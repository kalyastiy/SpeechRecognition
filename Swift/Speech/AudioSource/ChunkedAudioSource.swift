//
//  ChunkedAudioSource.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 22.10.2019.
//

import Foundation
import AVFoundation

//Декоратор для источника звука, позволяющий получать фрагменты сс продолжительностью задавнного временного интервала.

final class ChunkedAudioSource {
    
    weak var delegate: AudioSourceDelegate? {
        didSet {
            audioSource.delegate = (self.delegate != nil) ? self : nil
        }
    }
    
    private var audioSource: AudioSource
    private var buffer: ChunkedAudioBuffer

    
    //Инициализация декоратора для получения аудиопотока фрагментами определеннойо длины.
    //-audiosource: Декорируемый источник аудио.
    //-buffer: Буффер, принимающий данные аудиопотока и накапливающий их до определенного временного интервала.
    //-returnts: Задекорированный источник аудиоданных.
    
    init(_ audioSource: AudioSource, buffer: ChunkedAudioBuffer) {
        self.audioSource = audioSource
        self.buffer = buffer
        self.buffer.delegate = self
    }
    
    //Инициализация декоратора временным интервалом накапливаемого фрагмета голоса
    //-audioSource: Декорируемый источник аудио
    //-perFrameInterval: Временной интервал накапливаемого фрагмента аудиоданных .
    
    convenience init (_ audioSource: AudioSource, perFrameInterval: TimeInterval) {
        self.init(audioSource, buffer: PersistantChunkedAudioBuffer(chunkDuration: perFrameInterval))
    }
}

extension ChunkedAudioSource: ChunkedAudioBufferDelegate {
    
    func buffer(_ buffer: ChunkedAudioBuffer, didAccumulateChunk data: AVAudioPCMBuffer) {
        delegate?.audioSource(audioSource, didReceiveData: data)
    }
    
    func buffer(_ buffer: ChunkedAudioBuffer, didFailWithError error: Error) {
        audioSource.cancel()
        delegate?.audioSource(audioSource, didFailWithError: error)
    }
}


extension ChunkedAudioSource: AudioSourceDelegate {
    
    func audioSourceDidStartListening(_ audioSource: AudioSource) {
        delegate?.audioSourceDidStartListening(audioSource)
    }
    
    func audioSourceDidStopListening(_ audioSource: AudioSource) {
        delegate?.audioSourceDidStopListening(audioSource)
    }
    
    func audioSource(_ audioSource: AudioSource, didReceiveData data: AVAudioPCMBuffer) {
        buffer.write(data)
    }
    
    func audioSource(_ audioSource: AudioSource, didUpdatePower power: Float) {
        delegate?.audioSource(audioSource, didUpdatePower: power)
    }
    
    func audioSource(_ audioSource: AudioSource, didFailWithError error: Error) {
        delegate?.audioSource(audioSource, didFailWithError: error)
    }
}


extension ChunkedAudioSource: AudioSource {
    
    var isRunning: Bool {
        return audioSource.isRunning
    }
    
    func start() {
        audioSource.start()
    }
    
    func stop() {
        flushLastPartFromBufferIfNeeded()
        audioSource.stop()
    }
    
    private func flushLastPartFromBufferIfNeeded() {
        guard let lastData = buffer.flush() else { return }
        delegate?.audioSource(self, didReceiveData: lastData)
    }
    
    func cancel() {
        audioSource.cancel()
    }
}
