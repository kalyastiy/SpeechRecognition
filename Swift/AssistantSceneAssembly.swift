//
//  AssistantSceneAssembly.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 24.10.2019.
//

import Foundation
import AVFoundation

//Фабрика по созданию сцены диалога с помощником

final class AssistantSceneAssembly: NSObject {
    
    var testChatObj : TestChatSendRequest?
    
    @objc
    public static func instantiate (config: NSArray) -> TestChatSendRequest {
        //let host = "wss://vpstest.online.sberbank.ru:9443/vps/"
        let host = "wss://vpwebfront.com:18010/"
        //let host = "wss://renenet176.sigma.sbrf.ru:9443/vps/"
        let sslPinningEnable = true
//        var configuration = VPS.Configuration(host: host, sslPinningEnabled: sslPinningEnable, enableLogging: true, userId: config.userId, userChannel: config.userChannel, ttsEngine: config.ttsEngine, sttEngine: config.sttEngine, dubbing: config.dubbing)
        var configuration = VPS.Configuration(
            host: host,
            sslPinningEnabled: sslPinningEnable,
            enableLogging: true,
            userId: config[0] as! String,
            userChannel: config[1] as! String,
            ttsEngine: config[2] as! String,
            sttEngine: config[3] as! String,
            dubbing: config[4] as! Int
        )

        
//        self.userChannel = userChannel
//        self.ttsEngine = ttsEngine
//        self.sttEngine = sttEngine
//        self.dubbing = dubbing

        configuration.sslCertificates = [Certificate]()
        let vps = VPS(configuration: configuration)
        
        let assistantControllerTemp = AssistantController(processingService: vps)

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(true, options: [.notifyOthersOnDeactivation])
            try session.setCategory(.playAndRecord, options: .defaultToSpeaker)
        } catch {
            NSLog("setCategory fails")
        }
        
        return TestChatSendRequest(assistantController: assistantControllerTemp, notificationCenter: NotificationCenter.default, audioSession: session)
    }
    
    
    private static var vps: VPS {
        let host = "wss://vpwebfront.com:18010/"
        let sslPinningEnable = true
        let certificates : [Certificate] = [
            SberbankCertificate.userTrustRsaCertificationAuthority,
            SberbankCertificate.sectigo,
            SberbankCertificate.vpwebfront,
            SberbankCertificate.ift,
            SberbankCertificate.psi,
            SberbankCertificate.prom,
            SberbankCertificate.testRoot,
            SberbankCertificate.testIssuing
        ].compactMap { $0 }  //СДЕЛАТЬ нет в Bandle необходимых сертификатов
        var configuration = VPS.Configuration(host: host, sslPinningEnabled: sslPinningEnable, enableLogging: true, userId: UUID().uuidString)
        configuration.sslCertificates = certificates
        let vps = VPS(configuration: configuration)
        return vps
    }
    
    
    private static var assistantController: AssistantController {
        return AssistantController(processingService: vps)
    }
    
    
    private static var speechRecognizerFactory: SpeechRecognizerFactory {
        let secondsPerChunk: TimeInterval = 1
        return SpeechRecognizerFactory(chunkDuration: secondsPerChunk)
    }

}
