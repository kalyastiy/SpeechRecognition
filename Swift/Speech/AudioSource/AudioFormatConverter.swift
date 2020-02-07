//
//  AudioFormatConverter.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 22.10.2019.
//

import Foundation
import AVFoundation

//Конвертер аудиобуффера в заданный формат.

protocol AudioFormatConverter {
    
    //Преобразование буффера к требуемому формату.
    //Note: Требуемый формат задается в сущности, реализующей прототип.
    //-buffer: Буффер для преобразования
    //-returnts: Преобразованный буфер требуемого формата
    //-throws: Ошибки, возникшие при преобразовании
    func convert(buffer: AVAudioPCMBuffer) throws -> AVAudioPCMBuffer
}


//Преобразователь аудиоданных из исходного формата в необходимый

final class AudioSourceFormatConverter {
    
    //-audioConverterInitializationError: Ошибка инициализации преобразователя.
    //-outputBufferCreationError: Ошибка инициализации результирующиего временного буффера.
    //-conversionError: Ошибка преобразования с приложенной внутренней ошибкой.
    enum Error: Swift.Error {
        case audioConverterInitializationError
        case outputBufferCreationError
        case conversionError(underlineError: NSError)
    }
    
    //Спецификации входного/выходного формата конвертера.
    struct ConverterIOFormat {
        
        //Исходный формат
        var from: AVAudioFormat
        
        //Формат после конвертации
        //swiftlint:disable:nexr identifier_name
        var to: AVAudioFormat
    }
    
    private let format: ConverterIOFormat
    private let audioConverter: AVAudioConverter
    
    //Инициализация преобразователя аудиоформатов.
    //-format: Настройка форматов для конвертации
    //-throws: Ошибки инициализации преобразователя
    init(format: ConverterIOFormat) throws {
        self.format = format
        guard let audioConverter = AVAudioConverter(from: format.from, to: format.to) else {
            throw Error.audioConverterInitializationError
        }
        self.audioConverter = audioConverter
    }
}

extension AudioSourceFormatConverter: AudioFormatConverter {
    
    func convert(buffer: AVAudioPCMBuffer) throws -> AVAudioPCMBuffer {
        let frameCapacity = calculateCapacity(for: buffer)
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format.to, frameCapacity: frameCapacity) else {
            throw Error.outputBufferCreationError
        }
        
        let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
            outStatus.pointee = AVAudioConverterInputStatus.haveData
            return buffer
        }
        
        var error: NSError?
        audioConverter.convert(to: pcmBuffer, error: &error, withInputFrom: inputBlock)
        if let error = error {
            throw Error.conversionError(underlineError: error)
        }
        return pcmBuffer
    }
    
    private func calculateCapacity(for buffer: AVAudioPCMBuffer) -> UInt32 {
        let inputRate = format.from.sampleRate
        let outputRate = format.to.sampleRate
        let sampleRateConversionRatio = inputRate / outputRate
        let capacity = UInt32(Double(buffer.frameCapacity) / sampleRateConversionRatio)
        return capacity
    }
}
