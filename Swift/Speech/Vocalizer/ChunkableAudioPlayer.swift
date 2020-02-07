//
//  ChunkableAudioPlayer.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 22.10.2019.
//

import Foundation
import AVFoundation

//Плеер для возспроизведения последовательных фрагментов голоса

class ChunkableAudioPlayer: NSObject, VoicePlayer {
    
    //-couldNotCreatePlayer: Ошибка создания back-плеера AVFoundation для фрагмента brokenChunk
    enum Error: Swift.Error {
        case couldNotCreatePlayer(brokenChunk: Data)
    }
    
    //Делагат событий плеера
    final weak var delegate: VoicePlayerDelegate?
    
    //Заголовок аудиофрагментов голоса. Содержит информацию о проигрываемом типе.
    private var header: VoiceFormatHeader
    
    //Плеер текущей проигрываемой последовательности фрагметов
    private var audioPlayer: AVAudioPlayer?
    
    private var buffer: ChunkBuffer = ChunkBuffer()
    private var paused: Bool?
    private var stopped = false

    //Флаг активности воспроизведения голоса
    final var isPlaying: Bool {
        return paused == false && (audioPlayer != nil || buffer.isEmpty == false) && stopped == false
    }
    
    required init(chunkFormatHeader: VoiceFormatHeader) {
        self.header = chunkFormatHeader
    }
    
    final func play() {
        guard let player = audioPlayer else { return }
        paused = false
        //player.play()
    }
    
    private func playNextChunkIfNeeded() {
        guard shouldPlayNextChunk() else { return }
        playNextChunk(with: buffer.flush())
    }
    
    private func shouldPlayNextChunk() -> Bool {
        return audioPlayer == nil && buffer.isEmpty == false
    }
    
    private func playNextChunk(with data: Data) {
        //AVAudioPlayer требует заголовка аудиофайла для корректного проигрывания.
        //Поэтому к каждому последующему чанку добавляем сохранннеый заголовок
        let chunkData = header.rawData + data
        guard let nextPlayer = try? setupAudioPlayer(with: chunkData) else {
            delegate?.audioPlayer(self, didFailWithError: Error.couldNotCreatePlayer(brokenChunk: chunkData))
            return
        }
        
        nextPlayer.delegate = self
        audioPlayer = nextPlayer
        play()
    }
    
    //Фабричный метод для создания back-плеера для проигрывания
    //-data: Фрагмент голоса со склеенным заголовком
    //-returnts: Плеер для воспроизведения фрагмента.
    //-Throws:Ошибка при создании back-плеера AVFoundation
    func setupAudioPlayer(with data: Data) throws -> AVAudioPlayer {
        return try AVAudioPlayer(data: data)
    }
    
    final func pause() {
        paused = true
        audioPlayer?.pause()
    }
    
    final func stop() {
        paused = nil
        audioPlayer?.stop()
        stopped = true
    }
    
    final func append(data: Data) {
        buffer.append(data)
        playNextChunkIfNeeded()
    }
    
}

extension ChunkableAudioPlayer: AVAudioPlayerDelegate {
    
    private var playbackCanBeFinished: Bool {
        return buffer.isEmpty && audioPlayer == nil
    }
    
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        clearPlayer()
        paused = nil
        if playbackCanBeFinished {
            delegate?.audioPlayerDidFinishPlaying(self, successfully: true)
        } else {
            playNextChunkIfNeeded()
        }
    }
    
    private func clearPlayer() {
        audioPlayer?.delegate = nil
        audioPlayer?.stop()
        audioPlayer = nil
    }
}




//Буффер для голосовых фрагментов

final class ChunkBuffer {
    
    private var buffer: AtomicBox<Data> = .init(Data())
    
    var isEmpty: Bool {
        return buffer.value.isEmpty
    }
    
    //Добавить новый фрагмет в буффер
    //-data: Новый голосовй фрагмент
    func append(_ data: Data) {
        buffer.mutate { $0.append(data) }
    }
    
    //Опустошить буффер
    //-returnts: Все фрагменты, находяющиеся в буффере на момент вызова
    func flush() -> Data {
        let unplayedData = buffer.value
        buffer = .init(Data())
        return unplayedData
    }
}


//Упаковка обьекта для потокобезопасного доступа
final class AtomicBox<Value> {
    
    private let queue = DispatchQueue(label: "ru.sberbank.assistant.voice.atomic.queue")
    private var boxedValue: Value
    
    var value: Value {
        return queue.sync { self.boxedValue }
    }
    
    init(_ value: Value) {
        self.boxedValue = value
    }
    
    func mutate(_ transform: @escaping (inout Value) -> Void) {
        queue.async(flags: .barrier) {
            transform(&self.boxedValue)
        }
    }
}
