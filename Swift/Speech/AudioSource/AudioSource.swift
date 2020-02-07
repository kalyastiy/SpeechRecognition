//
//  AudioSource.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 22.10.2019.
//

import Foundation
import AVFoundation

//Буффер для аудио по определению временным фрагментам

public protocol AudioSource {
    
    //Делегат событий наблюдателя за звуком с микрофона.
    var delegate: AudioSourceDelegate? { get set }
    
    //Запущен ли мониторинг звука сос стандартного аудиовхода устройства
    var isRunning: Bool { get }
    
    //Начать запись звука со стандартного аудиовхода устройства
    func start()
    
    //Остановить запись звука со стандартного аудиовхода устройства.
    //Накопившиеся пакеты дойдут до делегата
    func stop()
    
    //Остановить запись звука со стандартного аудиовхода устройства
    // Important: Немедленная остановка просушивания аудиовхода
    func cancel()
}


//Делагат событий аудиоисточника

public protocol AudioSourceDelegate: AnyObject {
    
    //Событие, уведомляющее о начале записи аудиопотока со стандартного аудиовыхода устройства
    // -audiosorce: Аудиоисточник, инициирующий событие
    func audioSourceDidStartListening(_ audioSource: AudioSource)
    
    //Событие, уведомляющее о завершении записи аудиопотока со стандартного аудиовыхода устройства
    func audioSourceDidStopListening(_ audioSource: AudioSource)
    
    //Событие, уведомляющее о получении нового буффера аудиофрагментво с аудиопотока
    // -data: Полученный аудибуффер, со стандартного выхода устройства
    func audioSource(_ audioSource: AudioSource, didReceiveData data: AVAudioPCMBuffer)
    
    //Событие, уведомляющее об изменении уровня громкости сигнала с источника звука
    // -power: Новое значение громкости сигнала в диапозоне [0..1]
    func audioSource(_ audioSource: AudioSource, didUpdatePower power: Float)
    
    //Событие, уведомляющее об аварийном завершении работы источника звука по причине возникновения ошибки
    //Important: После возникновения данного события, аудиоисточник ссчитается невалидным и не может больше получать звук с аудиовыхода
    func audioSource(_ audioSource: AudioSource, didFailWithError error: Error)

}
