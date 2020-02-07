//
//  TestChatSendRequest.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 24.10.2019.
//

import Foundation
import AVFoundation
//import SwiftySound

final class TestChatSendRequest: CDVPlugin, AVAudioPlayerDelegate  {
        
    
    private let assistantController: AssistantController
    private let notificationCenter: NotificationCenter
    private let audioSession: AVAudioSession
    private let firstMessage = true
    
    var mutableVoice : NSMutableData?
    var voiceURL : URL?
    
    @objc
    public weak var delegate: RecivedVPSDelegate?

    
    init(assistantController: AssistantController, notificationCenter: NotificationCenter, audioSession: AVAudioSession) {
        self.assistantController = assistantController
        self.notificationCenter = notificationCenter
        self.audioSession = audioSession
        super.init()
        self.assistantController.setDelegate(self)
        
        mutableVoice = NSMutableData()
    }
    
        
    @objc
    public func createSocket () {
    }
    
    @objc
    public func startVoiceRecogizer () {
        didStartRecordUserVoice()
    }
    
    @objc
    public func stoptVoiceRecogizer () {
        didStopRecordUserVoice()
    }

    @objc
    public func sendMessageWithText (_ text: String) {
        didSendMessageWithText(text)
    }

}


extension TestChatSendRequest: AssistantControllerDelegate {
    func didFinishTranscription() {
        delegate?.recognitionSessionDidFinishedRecivedVoice(true, voice: Data())
    }
    
    
    func didReceivedMessage(text: String) {
        print("ОТВЕТ ПЕРЕВОДА ОТ VPS text \(text)")
        delegate?.reciveMessage(text)
    }
    
    func didReceivedMessage(payload: String) {
        
    }
    
    func didReceivedMessage(transcript: String) {
        print("ОТВЕТ ПЕРЕВОДА ОТ VPS  transcript   \(transcript)")
        delegate?.reciveMessage(transcript)
    }
    
    func didFinishedMessage() {
        delegate?.finish()
    }
    
    func recognitionSessionDidFinishedRecivedVoice(_  last : Bool, voice: Data) {
                
        mutableVoice?.append(voice)
        if last == true {
            
//            delegate?.recognitionSessionDidFinishedRecivedVoice(last, voice: voice)
//
//
//            var data = mutableVoice!.copy() as! Data
//            if (!data.isEmpty) {
//
//                delegate?.recognitionSessionDidFinishedRecivedVoice(last, voice: voice)

                
                
//                WAVRepair.repairWAVHeader(data: &data)
//                saveVoiceToDisk(voiceData: data)
//
//                let imgFolderURL = FileManager.documentDirectoryURL.appendingPathComponent("Voice")
//
//                do {
//                    let audioPlayer = try AudioPlayerSwift(contentsOf: imgFolderURL.appendingPathComponent("voice1").appendingPathExtension("wav"))
//                    audioPlayer.play()
//                    audioPlayer.fadeTo(volume: 0.95, duration: 20.0)
//                } catch {}
//
                
                
                
                
                //Sound.play(url: imgFolderURL.appendingPathComponent("voice1").appendingPathExtension("wav"))
                /*do {
                    let player = try AVAudioPlayer(contentsOf: imgFolderURL.appendingPathComponent("voice1").appendingPathExtension("wav"), fileTypeHint: "wav")
                    player.play()
                } catch {}*/
                
                
                
                
//                delegate?.recognitionSessionDidFinishedRecivedVoice(last, voice: data)
//            } else {
//                delegate?.failError("Не получили данные для воспроизведения")
//            }
        }
        
                
    }
        
    
    private func saveVoiceToDisk(voiceData: Data) {
        
        let imgFolderURL = FileManager.documentDirectoryURL.appendingPathComponent("Voice")
        
        if !FileManager.default.fileExists(atPath: imgFolderURL.path) {
            do {
                try FileManager.default.createDirectory(atPath: imgFolderURL.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                NSLog("Couldn't create document directory")
            }
        }
        
        do {
            try voiceData.write(to: imgFolderURL.appendingPathComponent("voice1").appendingPathExtension("wav"))
        }
        catch let err {
            print(err.localizedDescription)
        }
        
    }


    func didReceivedError(error: Error) {
        delegate?.failError(error.localizedDescription)
        print("Что-то пошло не так. Попробуйте задать вопрос еще раз.")
    }
}

extension TestChatSendRequest: MessageInputViewControllerDelegate {
    
    func didSendMessageWithText(_ text: String) {
        assistantController.sendMessage(text: text)
    }
    
    func didStartRecordUserVoice() {
        assistantController.startVoiceTranscription()
    }
    
    func didStopRecordUserVoice() {
        assistantController.stopVoiceTranscription()
    }
}



internal class WAVRepair {

    /**
     Convert a big-endian byte buffer to a UTF-8 encoded string.
     - parameter data: The byte buffer that contains a big-endian UTF-8 encoded string.
     - parameter offset: The location within the byte buffer where the string begins.
     - parameter length: The length of the string (without a null-terminating character).
     - returns: A String initialized by converting the given big-endian byte buffer into
        Unicode characters using a UTF-8 encoding.
     */
    private static func dataToUTF8String(data: Data, offset: Int, length: Int) -> String? {
        let range = Range(uncheckedBounds: (lower: offset, upper: offset + length))
        let subdata = data.subdata(in: range)
        return String(data: subdata, encoding: String.Encoding.utf8)
    }

    /**
     Convert a little-endian byte buffer to a UInt32 integer.
     - parameter data: The byte buffer that contains a little-endian 32-bit unsigned integer.
     - parameter offset: The location within the byte buffer where the integer begins.
     - returns: An Int initialized by converting the given little-endian byte buffer into an unsigned 32-bit integer.
     */
    private static func dataToUInt32(data: Data, offset: Int) -> Int {
        var num: UInt8 = 0
        let length = 4
        let range = Range(uncheckedBounds: (lower: offset, upper: offset + length))
        data.copyBytes(to: &num, from: range)
        return Int(num)
    }

    /**
     Returns true if the given data is a WAV-formatted audio file.
     To verify that the data is a WAV-formatted audio file, we simply check the "RIFF" chunk
     descriptor. That is, we verify that the "ChunkID" field is "RIFF" and the "Format" is "WAVE".
     Note that this does not require the "ChunkSize" to be valid and does not guarantee that any
     sub-chunks are valid.
     - parameter data: The byte buffer that may contain a WAV-formatted audio file.
     - returns: `true` if the given data is a WAV-formatted audio file; otherwise, false.
     */
    internal static func isWAVFile(data: Data) -> Bool {

        // resources for WAV header format:
        // [1] http://unusedino.de/ec64/technical/formats/wav.html
        // [2] http://soundfile.sapp.org/doc/WaveFormat/
        let riffHeaderChunkIDOffset = 0
        let riffHeaderChunkIDSize = 4
        let riffHeaderChunkSizeOffset = 8
        let riffHeaderChunkSizeSize = 4
        let riffHeaderSize = 12

        guard data.count >= riffHeaderSize else {
            return false
        }

        let riffChunkID = dataToUTF8String(data: data, offset: riffHeaderChunkIDOffset, length: riffHeaderChunkIDSize)
        guard riffChunkID == "RIFF" else {
            return false
        }

        let riffFormat = dataToUTF8String(data: data, offset: riffHeaderChunkSizeOffset, length: riffHeaderChunkSizeSize)
        guard riffFormat == "WAVE" else {
            return false
        }

        return true
    }

    /**
     Repair the WAV header for a WAV-formatted audio file produced by Watson Text to Speech.
     - parameter data: The WAV-formatted audio file produced by Watson Text to Speech.
        The byte data will be analyzed and repaired in-place.
     */
    internal static func repairWAVHeader(data: inout Data) {

        // resources for WAV header format:
        // [1] http://unusedino.de/ec64/technical/formats/wav.html
        // [2] http://soundfile.sapp.org/doc/WaveFormat/
        // update RIFF chunk size
        let fileLength = data.count
        var riffChunkSize = UInt32(fileLength - 8)
        let riffChunkSizeData = Data(bytes: &riffChunkSize, count: MemoryLayout<UInt32>.stride)
        data.replaceSubrange(Range(uncheckedBounds: (lower: 4, upper: 8)), with: riffChunkSizeData)

        // find data subchunk
        var subchunkID: String?
        var subchunkSize = 0
        var fieldOffset = 12
        let fieldSize = 4
        while true {
            // prevent running off the end of the byte buffer
            if fieldOffset + 2*fieldSize >= data.count {
                return
            }

            // read subchunk ID
            subchunkID = dataToUTF8String(data: data, offset: fieldOffset, length: fieldSize)
            fieldOffset += fieldSize
            if subchunkID == "data" {
                break
            }

            // read subchunk size
            subchunkSize = dataToUInt32(data: data, offset: fieldOffset)
            fieldOffset += fieldSize + subchunkSize
        }

        // compute data subchunk size (excludes id and size fields)
        var dataSubchunkSize = UInt32(data.count - fieldOffset - fieldSize)

        // update data subchunk size
        let dataSubchunkSizeData = Data(bytes: &dataSubchunkSize, count: MemoryLayout<UInt32>.stride)
        data.replaceSubrange(Range(uncheckedBounds: (lower: fieldOffset, upper: fieldOffset+fieldSize)), with: dataSubchunkSizeData)
    }
}



extension FileManager {
    
    static var documentDirectoryURL: URL {
        let documentDirectoryURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        return documentDirectoryURL
    }
    
}




protocol MessageInputViewControllerDelegate: AnyObject {
    func didSendMessageWithText(_ text: String)
    func didStartRecordUserVoice()
    func didStopRecordUserVoice()
}




