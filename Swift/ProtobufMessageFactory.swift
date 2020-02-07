//
//  ProtobufMessageFactory.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 23.10.2019.
//

import Foundation
import UIKit

//Конкретаня фабрика по производству Protobuf-сообщений
struct ProtobufMessageFactory {
    
    let userId: String
    let token: String
    let userChannel: String
    let ttsEngine: String
    let sttEngine: String
    let dubbing: Int

    //        self.userChannel = userChannel
    //        self.ttsEngine = ttsEngine
    //        self.sttEngine = sttEngine
    //        self.dubbing = dubbing

    
    init(userId: String, token: String, userChannel: String, ttsEngine: String, sttEngine: String, dubbing: Int) {
        self.userId = userId
        self.token = token
        
//        self.userChannel = "AFINA" //userChannel
        self.userChannel = userChannel
        self.ttsEngine = ttsEngine
        self.sttEngine = sttEngine
        self.dubbing = dubbing

        
        forceLoadMessages()
    }
    
    //#crutch Google Protobuf внутри десериализации обращается по objc_getClass,
    //и если класс не был загружен в dispatch_table, срабатывает assert.
    //Происходит это еще из-за того что VoiceProcessingServiceSDK линкуется статически,
    //Если бы была динамическая линковка, то можно было бы решить через добавление -Objc в флаги Id.
    
    private func forceLoadMessages() {
        GPBGenMessage.load()
        GPBGenSettings.load()
        GPBGenVoice.load()
        GPBGenText.load()
        GPBGenStatus.load()
        GPBGenDevice.load()
        GPBGenSystemMessage.load()

    }
}


extension ProtobufMessageFactory: MessageFactory {
    
    func createInitialMessage(messageId: Int) -> Message {
        
        let device = GPBGenDevice()
        
        device.platformName = "iOS"
        device.platformVersion = UIDevice.current.systemVersion//"MP_IOS_4235.2558.25"//UIDevice.current.systemVersion
        device.channel = "mobile"//"AFINA"
        device.clientType = "iOS mobile"
        
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String // example: 1.0.0
//        let build = dictionary["CFBundleVersion"] as! String // example: 42

        device.channelVersion = version//"1.0.0"
        
        let message = GPBGenMessage()
        message.messageId = Int64(messageId)
        message.userId = userId
        message.userChannel = userChannel//"KURS_MP"//Наименование канала - выдается NLP платформой
        message.last = 1//-1 //1
//        message.token = token
        message.device = device
                
        return ProtobufMessage(proto: message)
    }
    
    func createMessage(with text: String, messageId: Int) -> Message {
    
        let textData = GPBGenText()
        textData.data_p = text
        
        let message = GPBGenMessage()
        message.messageId = Int64(messageId)
        message.userId = userId
        message.userChannel = userChannel//"KURS_MP"//Наименование канала - выдается NLP платформой
        message.last = 1
//        message.token = token
        message.text = textData
        
        
        return ProtobufMessage(proto: message)
    }
    
    func createMessage(with voice: Data, messageId: Int, last: Bool) -> Message {
        
        let voiceMessage = GPBGenVoice()
        voiceMessage.data_p = voice
        
        let message = GPBGenMessage()
        message.messageId = Int64(messageId)
        message.userId = userId
        message.userChannel = userChannel//"KURS_MP"//Наименование канала - выдается NLP платформой
        message.last = -1 //last ? 1 : -1
//        message.token = token
        message.voice = voiceMessage
        
        return ProtobufMessage(proto: message)
        
    }
    
    func createMessage(data: Data) throws -> Message {
        return try ProtobufMessage(binaryData: data)
    }
    
    
    //вызываю при формировании stt
    func createMessage(muted: Bool, messageId: Int) -> Message {
        
//        Режим stt:
//        Dubbing = -1
//        Echo = 1
//        Stt_engine = “default”
//        stt_auto_stop = 1
        
        
        let settings = GPBGenSettings()
        settings.dubbing = -1 //muted ? -1 : 1
        settings.echo = 1
        settings.sttEngine = sttEngine//"default"
        settings.sttAutoStop = 1
        
//        settings.sttAutoStop = 1
//        settings.ttsEngine = "default"
//        settings.sttEngine = "default"
//        settings.echo = 1  //-1
//        settings.devMode = -1

        
        let message = GPBGenMessage()
        message.messageId = Int64(messageId)
        message.userId = userId
        message.userChannel = userChannel//"KURS_MP"//Наименование канала - выдается NLP платформой
        //message.token = token
        message.settings = settings
        
        return ProtobufMessage(proto: message)
    }
    
    //вызываю при формировании tts

    func createMessage(isEchoEnabled: Bool, messageId: Int) -> Message {
        
    
        let settings = GPBGenSettings()
//        settings.eisDisabled = eisEnable ? -1 : 1
        settings.echo = 1
        settings.dubbing = Int32(dubbing)
        settings.ttsEngine = ttsEngine//"default"
        
//        settings.sttAutoStop = 1
//        settings.ttsEngine = "default"
//        settings.sttEngine = "default"
//        settings.echo = 1  //-1
//        settings.devMode = -1
//        settings.dubbing = 1 //вообще не было dubbing

        
        let message = GPBGenMessage()
        message.messageId = Int64(messageId)
        message.userId = userId
        message.last = 1
        message.userChannel = userChannel//"KURS_MP"//Наименование канала - выдается NLP платформой
//        message.token = token
        message.settings = settings
        
        return ProtobufMessage(proto: message)

    }
}
