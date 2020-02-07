//
//  Certificate.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 21.10.2019.
//

import Foundation

//Сертификат безопасности для проверки сетевого соеденинения по протоколу SSL

public struct Certificate {
    
    //Тип сертификата и расширение его файла
    public enum Extension: String {
        case cer
        case der
        case per
    }
    
    //Сертификат в чистом представлении фреймворка Security
    public let raw: SecCertificate
    
    //Чистые данные сертификата
    public var data: Data {
        return SecCertificateCopyData(raw) as Data
    }
    
    //Краткая информация по сертификату (генерируется на основе спецификаций сертификата)
    public var summary: String {
        let summary = SecCertificateCopySubjectSummary(raw) as String?
        return summary ?? "unknown"
    }
    
    //Инициализатор сертификата по исходным данным из фреймворка Security
    public init(raw: SecCertificate) {
        self.raw = raw
    }
    
    //Инициализотор сертификата по локальному файлу в бандле
    public init?(name: String, certificateType: Extension, bundle: Bundle) {
        guard let certificate = Certificate.readCertificate(name: name, type: certificateType, in: bundle) else  { return nil }
        self.init(raw: certificate)
    }
    
    private static func readCertificate (name: String, type: Extension, in bundle: Bundle) -> SecCertificate? {
        guard let path = bundle.path(forResource: name, ofType: type.rawValue) else { return nil }
        let certificate = readCertificate(from: path)
        return certificate
    }
    
    private static func readCertificate (from path: String) -> SecCertificate? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }
        return SecCertificateCreateWithData(nil, data as CFData)
    }

    
    //Извлечение цепочки сертифкатов из обьекта Sectrust фреймворка Security
    // - Note: Метод-помощник для валидации сетевых соеденинений , т.к. в них приходится работать именно с обьектом SecTrust
    static func extract(from trust: SecTrust) -> [Certificate] {
        var certificates: [SecCertificate] = []
        
        for index in 0..<SecTrustGetCertificateCount(trust) {
            if let certificate = SecTrustGetCertificateAtIndex(trust, index) {
                certificates.append(certificate)
            }
        }
        
        return certificates.map { Certificate(raw: $0) }
    }
    
}
