//
//  VoicePlayer.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 22.10.2019.
//

import Foundation

//Протокол плеера проигрывания фрагментов голоса

protocol VoicePlayer {
    
    var isPlaying: Bool { get }
    var delegate: VoicePlayerDelegate? { get set }
    
    //Инициализатор плеера
    //-chunkFormatHeader: Заголовок проигрываемых фрагментов звука
    //Необходимо для коррекнтного склеивания последовательности фрагментов
    init(chunkFormatHeader: VoiceFormatHeader)
    
    //Начать проигрывание текущего буффера фрагментов или продолжить остановленный
    func play()
    
    //Приостановить воспроизвдение текущего фрагмента голоса
    func pause()
    
    //Остановка проигрывания голоса
    //-note: Может быть вызван единожды
    func stop()
    
    //Дополнение плеера новым фрагментом голоса
    //-note: При отсуствии текущего плеера воспроизведениея сразу начинается проигрывание нового фрагмента
    //-data: Новый фрагмент голоса для воспроизведения
    func append(data: Data)
}


//Делегат плеера воспроизведения голоса

protocol VoicePlayerDelegate: AnyObject {
    
    //Уведомляет о том, что плеер закончил воспроизведение всех фрагментов из буфера
    //- note: При возникновении ошибки воспроизведения или остановке плеера в ручном режиме будет вызыван
    //с флагом successfully = false
    //-player: Обьект, инициирующий событие
    //-flag: Флаг успешного завершения
    func audioPlayerDidFinishPlaying(_ player: VoicePlayer, successfully flag: Bool)
    
    //Уведомляет о том, что при декодировании нового фрагмента, возникла ошибка
    func audioPlayer(_ player: VoicePlayer, didFailWithError error: Error)

}


//Заголовок файла звукового формата

struct VoiceFormatHeader {
    
    enum Error: Swift.Error {
        case incorrectHeaderSize
        case incorrectRiftSubchunk
        case incorrectWaveSubchunk
    }
    
    static let headerSize = 44
    
    private enum Layout {
        static let riff: Range<Data.Index> = 0..<4
        static let wave: Range<Data.Index> = 8..<12
    }
    
    private(set) var rawData: Data
    
    init(with data: Data) throws {
        self.rawData = data
        try validateHeader(data)
    }
    
    private func validateHeader(_ data: Data) throws {
        try validateSize(data)
        try validateRiftSubchunk(data)
        try validateWaveSubchunk(data)

    }
    
    private func validateSize(_ data: Data) throws {
        guard data.count == VoiceFormatHeader.headerSize else {
            throw Error.incorrectHeaderSize
        }
    }
    
    private func validateRiftSubchunk(_ data: Data) throws {
        guard String(data: data.subdata(in: Layout.riff), encoding: .utf8) == "RIFF" else {
            throw Error.incorrectRiftSubchunk
        }
    }
    
    private func validateWaveSubchunk(_ data: Data) throws {
        guard String(data: data.subdata(in: Layout.wave), encoding: .utf8) == "WAVE" else {
            throw Error.incorrectWaveSubchunk
        }
    }

}
