//
//  PersistantAudioChunk.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 22.10.2019.
//

import Foundation
import AVFoundation

class PersistantAudioChunk: AudioChunk {
    
    //-storageAlreadyBeenFlushed: Хранилище уже было принудительно освобождено
    //-storageAlreadyFilled: Хранилище уже заполнено
    enum PersistantAudioChunkError: Swift.Error {
        case storageAlreadyBeenFlushed
        case storageAlreadyFilled
    }
    
    private let maxFramesCount: AVAudioFrameCount
    
    final private(set) var frames: AVAudioFrameCount = 0
    final private(set) var storage: ChunkStorage?
    
    final var filled: Bool {
        return frames >= maxFramesCount
    }

    
    init(id: String, format: AVAudioFormat, maxFramesCount: UInt32, fileManager: FileManager, folder: URL) throws {
        self.maxFramesCount = AVAudioFrameCount(maxFramesCount)
        self.storage = try storage(id: id, folder: folder, format: format, fileManager: fileManager)
    }
    
    func storage(id: String, folder: URL, format: AVAudioFormat, fileManager: FileManager) throws -> ChunkStorage {
        return try ChunkFile(url: PersistantAudioChunk.url(forChunkIdentifier: id, in: folder), format: format, fileManager: fileManager)
    }
    
    
    private static func url(forChunkIdentifier id: String, in folder: URL) -> URL {
        return folder.appendingPathComponent("chunk-\(id).wav")
    }
    
    convenience init(format: AVAudioFormat, maxFramesCount: UInt32) throws {
        try self.init(id: UUID().uuidString, format: format, maxFramesCount: maxFramesCount, fileManager: FileManager.default,
                      folder: URL(fileURLWithPath: NSTemporaryDirectory()))
    }
    
    final func write(_ buffer: AVAudioPCMBuffer) throws {
        guard let storage = storage else { throw PersistantAudioChunkError.storageAlreadyBeenFlushed }
        guard !filled else { throw PersistantAudioChunkError.storageAlreadyFilled }
        try storage.write(from: buffer)
        frames += buffer.frameLength
    }
    
    func flush() -> AVAudioPCMBuffer? {
        guard let storage = storage else { return nil }
        let buffer = try? storage.flush()
        self.storage = nil
        return buffer
    }
    
}



//Хранилище для голосовых данных

protocol ChunkStorage {
    
    //Запись новых аудиоданных
    //-buffer: Новый аудиофрагмент
    func write(from buffer: AVAudioPCMBuffer) throws
    
    //Выгрузка текущих наколпенных аудиоданных.
    //-returns: Накопленный аудиобуффер
    func flush() throws -> AVAudioPCMBuffer
}



//Файл для записи аудиофрагментов и последующего их извлечения
//Importatnt: При выгрузке аудиоданных, файл удаляется из файловой системы и обьект становится
//недоступным для дальнейшей записи/чтения

final class ChunkFile {
    
    //-fileDoesNotExistOnDisk: Ассоциированный файл отсуствует в файловой системе устройства
    //-writingBufferFormatIsIncorrect: Новый пакет аудиоданных имеет неверный формат, с которым был инициализирован обьект файла
    
    enum ChunkFileError: Swift.Error {
        case fileDoesNotExistOnDisk
        case writingBufferFormatIsIncorrect
    }
    
    private var file: AVAudioFile?
    private var fileManager: FileManager
    
    //Инициализация файла для записи аудиофрагментов на диск по указанному пути.
    //-url: Путь для сохранения файла.
    //-format: Формат записываемых аудиоданных
    //-fileManager: Менеджер по работе с файловой системой
    //-Throws: Ошибки инициализации аудиофайла на диске
    
    init(url: URL, format: AVAudioFormat, fileManager: FileManager) throws {
        self.file = try AVAudioFile(forWriting: url, settings: format.settings, commonFormat: format.commonFormat, interleaved: format.isInterleaved)
        self.fileManager = fileManager
    }
}


extension ChunkFile: ChunkStorage {
    
    func flush() throws -> AVAudioPCMBuffer {
        guard
            let url = file?.url,
            let format = file?.processingFormat,
            let data = try? Data(contentsOf: URL(fileURLWithPath: url.path)),
            let result = data.makePCMBuffer(format: format)
            else {
                throw ChunkFileError.fileDoesNotExistOnDisk
        }
        free()
        try cleanup(url: url)
        return result
    }
    
    private func instantiateReadingFile(url: URL, format: AVAudioFormat, length: UInt32) throws -> (AVAudioFile, AVAudioPCMBuffer) {
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: length)!
        let proceccingFile = try AVAudioFile(forReading: url)
        return (proceccingFile, buffer)
    }
    
    private func free() {
        file = nil
    }
    
    private func cleanup(url: URL) throws {
        try fileManager.removeItem(at: URL(fileURLWithPath: url.path))
    }
    
    func write(from buffer: AVAudioPCMBuffer) throws {
        guard let file = file else {
            throw ChunkFileError.fileDoesNotExistOnDisk
        }
        guard buffer.format == file.processingFormat else {
            throw ChunkFileError.writingBufferFormatIsIncorrect
        }
        try file.write(from: buffer)
    }
}
