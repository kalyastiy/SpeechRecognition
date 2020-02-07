//
//  ChunkedAudioBuffer.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 22.10.2019.
//

import Foundation
import AVFoundation

//Протокол, уведомляющий о событиях ChunkedAudioBuffer

protocol ChunkedAudioBufferDelegate: AnyObject {
    
    //Событие, уведомляющее о получении нового накопленного фрагмента аудиоданных , необходимого временно интервала
    // -buffer: Буффер, инициирующий событие
    // -data: Накопленный фрагмент аудиоданных необходимого временного интервала
    func buffer(_ buffer: ChunkedAudioBuffer, didAccumulateChunk data: AVAudioPCMBuffer)
    
    //Событие, уведомляющее об аварайином завершении работы буффера
    //Important: После генерации данного события, буффер прекращает свою работу и для ее возобновления необходимо создать его новую сущность
    // -buffer: Буффер, инициирующий событие
    // -error: Сгенерированная ошибка, из-за которой была остановлена работа буфера
    func buffer(_ buffer: ChunkedAudioBuffer, didFailWithError error: Error)
}

protocol ChunkedAudioBuffer {
    
    
    //Делагат буффера, принимающий событиия во время накопления голосовых фрагментов.
    var delegate: ChunkedAudioBufferDelegate? { get set }
    
    //Запись нового аудиофрагмента в накопительный буффер.
    // -buffer: Новый аудиофрагмент
    func write(_ buffer: AVAudioPCMBuffer)
    
    //Извлечение накопленного аудиофрагмента из буффера в ручном режиме, аудиофрагмент не обязательно будет заданного времменого интервала
    // - Note: Даннный метод стоит вызвать только в том случае, если вы хотите закончить запись аудиопотока и понимаете, что вам нужно извлечь
    //оставшиеся данные для последующией обработки
    func flush() -> AVAudioPCMBuffer?
}
