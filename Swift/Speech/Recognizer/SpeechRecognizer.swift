//
//  SpeechRecognizer.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 22.10.2019.
//

import Foundation

//Протокол обьекта для распознования речи пользоватля
//Importatnt: Перед началом работы с обьектом необходимо настроить аудиосессию устройства с помощью класса AVAudioSession
//Note: Пререквизиты для корректной работый функции распознования:
//* Пользователь дал разрешение на использования микрофона устройства
//* Аудиосессия приложения находится в активном состоянии и категоиря устновлена в состояние ".reocrd"

public protocol SpeechRecognizer {
    
    var delegate: SpeechRecognizerDelegate? { get set }
    
    //Начать процесс запись звука для расспознования речи
    // -Throws: Ошибки инициализации компонентво распознования (аудиоисточник, сессия сервиса и тд)
    func startRecording()
    
    //Остановить процесс записи речи пользователя
    //Вызов метода говорит о том, что в сервис распознования речи больше не будет поступать голосовых фрагментов.
    //Далее он пришлет конечный результат распознавания своему делегату
    func stopRecording()
    
    //Отмена распознавания речи. После вызова данного метода, процесс совершит принудительную остановку и делегат больше
    //не получит ни одного события
    func cancelRecording()

}


public protocol SpeechRecognizerDelegate: AnyObject {
    
    //Событие, уведомляющее о начале записи аудиопотока с источника звука
    // -recognizer: Обьект распознования, инициирующий событие
    func recognizerDidStartRecording(_ recognizer: SpeechRecognizer)
    
    //Событие, уведомляющее о завершении записи аудиопотока с источника звука
    //Note: после прихода данного ссобытия стоит ожидать послднего результат распознования
    //и завершения данного процесса
    func recognizerDidFinishRecording(_ recognizer: SpeechRecognizer)
    
    //Событие, уведомляющее об изменении уровня громкости сигнала с источника звука
    // -power: Новое значение громкости сигнала в диапозоне [0..1]
    func recognizer(_ recognizer: SpeechRecognizer, didUpdatePower power: Float)

    //Событие, уведомляющее о получении нового результата распознования в виде текста
    // -data: Полученный аудибуффер, со стандартного выхода устройства
    func recognizer(_ recognizer: SpeechRecognizer, didReceiveResult result: String)

    //Событие, уведомляющее об успешном завершении процесса распознования речи
    //Important: После вызова данного метода, обьект помечается невалидным и для запуска новой сесси
    //распознования необходимо создать новый обьект
    func recognizerDidFinishRecognition(_ recognizer: SpeechRecognizer)

    
    //Событие, уведомляющее об аварийном завершении процесса распознования речи по причине возникновения ошибки в одном из внутренних компонентов,
    //таких как аудиоисточник, конвертер, сервис распознования речи на бекенде
    //Important: После возникновения данного события, обьект помечается невалидным и для запуска новой сессии распознования необоходимо создать новый обьект
    func recognizer(_ recognizer: SpeechRecognizer, didFailWithError error: Error)
    
    
    //Вызвает при получении голового озвучивания текста на каждый полученный чанк голоса. с параметром последнего чанка
    func recognitionSessionDidFinishedRecivedVoice(_ last: Bool, voice: Data)

}


//Фабрика по созданию обьектов для распознавания речи.
//-Note: Создает обьект с заранее сконфигурированными временем ожидания

final class SpeechRecognizerFactory {
    
    private let chunkDuration: TimeInterval
    
    //Инициализация фабрики по созданию обьектов распознования речи.
    //-chunkDuration: Длина обрабатывамого фрагмента голоса в секундах
    init(chunkDuration: TimeInterval) {
        self.chunkDuration = chunkDuration
    }
    
    //Создать обьект для распознования речи с установленным ранее временным интервалом
    //-session: Сессия с VPS для распознования речи
    //-returns: Проинициализированный обьект для распознования речи по механизму VPS.
    //-throws: Ошибки создания обьекта распознования речи.
    func instantiate(with session: ProcessingSession) throws -> SpeechRecognizer {
        return try SBSpeechRecognizer.recognizer(with: session, chunkDuration: chunkDuration)
    }
}
