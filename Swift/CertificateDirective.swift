//
//  CertificateDirective.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 21.10.2019.
//

import Foundation
import Starscream

//Обьект для проверки trust store по цепочки доверенности сертификатов

final class CertificateDirective {
    
    //Флаг игнорерирования проверки на саомподписанные сертификаты
    var enableSelfSignedCertificates: Bool = false
    
    private let certificates: [Certificate]
    
    //Инициализатор проверки по цепочки доверенных сертификатов
    // - certificates: Массив доверенных сертификатов со стороны клиента
    init(certificates: [Certificate]) {
//        precondition(!certificates.isEmpty, "Цепочка сертификатов не может быть пустой")
        self.certificates = certificates
    }
}

extension CertificateDirective: TrustDirective {
    
    func isValid(_ trust: SecTrust, domain: String?) -> Bool {
        configureCertificateEvaluatingChainPolicy(trust, domain: domain)
        if enableSelfSignedCertificates {
            return verifyCertificate(trust: trust)
        }
        
        if evaluate(serverTrust: trust) {
            return verifyCertificate(trust: trust)
        }
        
        return false
    }
    
    private func configureCertificateEvaluatingChainPolicy (_ trust: SecTrust, domain: String? = nil) {
        let host = domain as CFString?
        let policy = SecPolicyCreateSSL(true, host)
        SecTrustSetPolicies(trust, policy)
    }
    
    private func verifyCertificate(trust: SecTrust) -> Bool {
        let certificatesToEvaluate = Certificate.extract(from: trust).map { $0.data }
        return certificates.map { $0.data }.contains(where: certificatesToEvaluate.contains)
    }
    
    private func evaluate(serverTrust trust: SecTrust) -> Bool {
        var trustResult: SecTrustResultType = .invalid
        let evaluationStatus = SecTrustEvaluate(trust, &trustResult)
        
        if evaluationStatus == errSecSuccess {
            let unspecified: SecTrustResultType = .unspecified
            let proceed: SecTrustResultType = .proceed
            return (trustResult == unspecified || trustResult == proceed)
        }
        
        return false
    }
    
}

// Скрытое соответсвие протоколу Starcream для инкапсуляции специфики в одном файле
extension CertificateDirective: Starscream.SSLTrustValidator {}


// Протокол для проверки защищенности сетевого соединения
public protocol TrustDirective {
    
    //Проверка trust store на валидное SSL соединение с сервером.
    // -trust: Обьект для проведения валидации на защищенность по стандарту X.509.
    // -domain: URL host для выполнения валидации (в некоторых сценариях этот параметр необходим для происхождения валидации)
    func isValid(_ trust: SecTrust, domain: String?) -> Bool
}
