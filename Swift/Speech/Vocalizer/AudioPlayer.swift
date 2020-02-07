//
//  AudioPlayer.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 29.10.2019.
//

import Foundation

//Базовый плеер для проигрывания аудио
protocol AudioPlayer {
    
    // true в случае, когда плеер проигрывает аудио в данный момент времени
    var isRunning: Bool { get }
    
    var delegate: AudioPlayerDelegate? { get set }
    
    //Запустить проигрывания аудио
    //-Throws: ошибка запуска плеера
    func start() throws
    
    //Приостановка плеера с возможностью дальнейшего воспроизведения аудио
    //Throws: Ошибки приостановки плеера
    func pause() throws
    
    //Остановка проигрывания данных.
    //Importtant: После вызова данных, метод, в дальнейшем плеер не сможет приогыварть аудио.
    //Throws: Ошибки остановки плеера
    func stop() throws
}

protocol AudioPlayerDelegate: AnyObject {
    func audioStreamPlayer(_ player: AudioPlayer, didFailWithError: Error)
}


//Плеер с возможностью проигрывания аудио потока
protocol StreamablePlayer: AudioPlayer {
    
    //Добавления новой последовательности аудиоданных для проигрывания
    //data: Новые аудиоданные
    func add(_ data: Data)
}
