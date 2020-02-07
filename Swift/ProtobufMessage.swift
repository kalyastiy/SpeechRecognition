//
//  ProtobufMessage.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 23.10.2019.
//

import Foundation

//Сообщение, использущее Protobuf для сериализации/десириализации
struct ProtobufMessage: Message {
 
    var text: String? {
        guard proto.text != nil, proto.text.data_p != nil, !proto.text.data_p.isEmpty else { return nil }
        let mutableString = NSMutableString(string: proto.text.data_p)
        CFStringTransform(mutableString, nil, "Any-Hex/Java" as NSString, true)
        return mutableString as String
    }
    
    var data: Data? {
        guard proto.voice != nil else { return nil }
        return proto.voice.data_p
    }
    
    var error: Error? {
        guard proto.status != nil, let description = proto.status.description_p, proto.messageId == 0 && !description.isEmpty else { return nil }
        let code = proto.status.code
        return Errors.proto(code: Int(code), description: description)
    }
    
    var last: Bool {
        return proto.last == 1
    }
    
    var sessionId: Int {
        return Int(proto.messageId)
    }
    
    var additionalInfo: String? {
        guard let info = proto.messageName else { return nil }
        return info
    }
    
    
    private enum Errors: Error {
        case serializingError
        case deserializingError
        case proto(code: Int, description: String)
        
        var localizedDescription: String {
            switch self {
            case .serializingError:
                return "Ошибка сериализации ProtobufMessage"
            case .deserializingError:
                return "Ошибка десериализации ProtobufMessage"
            case let .proto(code, description):
                return "Ошибка внутри сообощения Protobuf:\(code), \(description)"

            }
        }
        
    }
    
    
    //Десериализованная моделдь данных Protobuf
    private let proto: GPBGenMessage
    
    init(proto: GPBGenMessage) {
        self.proto = proto
    }
    
}


extension ProtobufMessage: BinarySerializable {
    
    init(binaryData: Data) throws {
        do {
            proto = try GPBGenMessage.parse(from: binaryData)
        } catch _ {
            throw Errors.deserializingError
        }
    }
    
    func binaryData() throws -> Data {
    
        if let data = proto.data() {
            return data
        } else {
            throw Errors.serializingError
        }
    }
    
    func description() -> String {
        return proto.debugDescription
    }
}
