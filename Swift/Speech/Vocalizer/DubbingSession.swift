//
//  DubbingSession.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 22.10.2019.
//

import Foundation
import AVFoundation

//Делегат, уведомляющий о событиях внутри сесси проигрывания голосса

protocol DubbingSessionDelegate: AnyObject {
    
    //Уведомление о завершении сессии проигрывания голоса
    // - session: Завершенная сесси.
    func sessionDidFinishDubbing(_ session: DubbingSession)
    
    //Уведомление о произошедшей ошибки
    //-session: Сессия в которой произошла ошибка
    func sessionDidReceiveError(_ session: DubbingSession, error: Error)
}


//Сессия проигрывания голоса
public class DubbingSession {
    
    //Делегат события сессии
    weak final var delegate: DubbingSessionDelegate?
    
    private final var player: VoicePlayer?
    private(set) final var finished: Bool = false
    private(set) final var isFirstChunk: Bool = true

    public init() { }
    
    deinit {
        player?.stop()
    }
    
    //Добавление новых данных к сессии проигрывания фрагментов голоса
    //-data: Новый фрагмент голоса
    public final func append(_ data: Data) {
        guard !data.isEmpty else { return }//== false else { return }
        
        if isFirstChunk == false {
            player?.append(data: data)
        } else {
            do {
                try proceedFirstChunkData(data)
            } catch {
                delegate?.sessionDidReceiveError(self, error: error)
            }
        }
    }
    
    private final func proceedFirstChunkData(_ data: Data) throws {
        isFirstChunk = false
        
        let chunkLayout = try FirstChunkLayout(data: data)
        try initializerPlayer(with: chunkLayout.header)
        
        guard let body = chunkLayout.body else { return }
        append(body)
    }
    
    
    public final func initializerPlayer(with headerData: Data) throws {
        let header = try VoiceFormatHeader(with: headerData)
        var player = setupPlayer(with: header)
        player.delegate = self
        self.player = player
    }
    
    //фабричный метод инициализации плеера фрагментом голоса
    //-header: Заголовок поступающих аудиофрагментов
    //-returns: Проинициализированный плеер
    func setupPlayer(with header: VoiceFormatHeader) -> VoicePlayer {
        return ChunkableAudioPlayer(chunkFormatHeader: header)
    }
    
    //Уведомление о том, что больше не будет фрагментов голоса для данной сессии.
    //- note: После вызова этого метода, сессия перестанет принимать любые фрагменты
    public final func finish() {
        finished = true
        finishDubbingSessionIfNeeded()
        
    }
    
    //Отмена сессии воспроизведения голосоа. Равносильно остановке проигрывания
    public final func cancel() {
        finished = true
        player?.stop()
        delegate?.sessionDidFinishDubbing(self)
    }
    
    private final func finishDubbingSessionIfNeeded() {
        if let player = player, player.isPlaying == false, finished {
            delegate?.sessionDidFinishDubbing(self)
        }
    }
}


extension DubbingSession: VoicePlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: VoicePlayer, successfully flag: Bool) {
        finishDubbingSessionIfNeeded()
    }
    
    final func audioPlayer(_ player: VoicePlayer, didFailWithError error: Error) {
        delegate?.sessionDidReceiveError(self, error: error)
        cancel()
    }
}



private struct FirstChunkLayout {
    
    enum Error: Swift.Error {
        case incorrectHeaderSize
    }
    
    private let headerSize = VoiceFormatHeader.headerSize
    
    private(set) var header: Data
    private(set) var body: Data?
    
    init(data: Data) throws {
        guard data.count >= headerSize else {
            throw Error.incorrectHeaderSize
        }
        header = data.subdata(in: 0..<headerSize)
        
        if data.count > headerSize {
            body = data.subdata(in: headerSize..<data.count)
        }
    }

}
