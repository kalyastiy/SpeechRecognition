//
//  PersistantChunkedAudioBuffer.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 22.10.2019.
//

import Foundation
import AVFoundation

//Буффер для аудио по определенным временным фрагментам

class PersistantChunkedAudioBuffer: ChunkedAudioBuffer {
    
    weak var delegate: ChunkedAudioBufferDelegate?
    
    final private var chunkDuration: TimeInterval
    final private var activeChunk: AudioChunk?
    
    //Инициализация буфера.
    //-chunkDuration: Времення продолжительность одного фрагмента.
    init(chunkDuration: TimeInterval) {
        self.chunkDuration = chunkDuration
    }
    
    final func write(_ buffer: AVAudioPCMBuffer) {
        do {
            let chunk = try currentChunk(for: buffer)
            try chunk.write(buffer)
            flushIfNeeded(chunk: chunk)
        } catch {
            delegate?.buffer(self, didFailWithError: error)
        }
    }
    
    
    private final func currentChunk(for buffer: AVAudioPCMBuffer) throws -> AudioChunk {
        if let chunk = activeChunk { return chunk }
        
        let chunk = try self.chunk(for: buffer.format,
                                   maxFramesCount: UInt32(Double(chunkDuration) * buffer.format.sampleRate))
        self.activeChunk = chunk
        return chunk
    }
    
    func chunk(for format: AVAudioFormat, maxFramesCount: UInt32) throws -> AudioChunk {
        return try PersistantAudioChunk(format: format, maxFramesCount: maxFramesCount)
    }
    
    private final func flushIfNeeded(chunk: AudioChunk) {
        guard
            chunk.filled, let data = flush() else { return }
        delegate?.buffer(self, didAccumulateChunk: data)
    }
    
    final func flush() -> AVAudioPCMBuffer? {
        let lastData = activeChunk?.flush()
        activeChunk = nil
        return lastData
    }
}




//Аудиофрагмент для буффера
protocol AudioChunk {
    
    //Если true, то фрагмент накопил аудиоданные определенного временного интервала, расчитанного из необходимого колличества байт ауидоинформации
    var filled: Bool { get }
    
    //Запись новых аудиоданных
    //-buffer: Новый аудиофрагмент
    func write(_ buffer: AVAudioPCMBuffer) throws
    
    //Извлечение наколпеннорго аудиофрагмента
    //-Note: Временной интервал аудиофрагмента не обязательно будет равен заданному
    //Извлекать его следует по проверки и записи нового фрагмента
    func flush() -> AVAudioPCMBuffer?
}
