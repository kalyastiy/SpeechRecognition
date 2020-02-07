//
//  SberbankCertificate.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 24.10.2019.
//

import Foundation


//Сертификаты СБОЛ
public enum SberbankCertificate {
    
    private final class BundleToken: NSObject { }
    
    static let bundle = Bundle(for: BundleToken.self)
    
    //Тестовый стенд снаружи.
    public static let vpwebfront: Certificate? = Certificate(name: "vpwebfront.com", certificateType: .cer, bundle: bundle)
    
    //Корневой сертификат для внешнего тествого стенда.
    public static let sectigo: Certificate? = Certificate(name: "Sectigo RSA Domain Validation Secure Server CA", certificateType: .cer, bundle: bundle)
    
    //Выпускающий сертификат для центра
    public static let userTrustRsaCertificationAuthority: Certificate? = Certificate(name: "USERTrust RSA Certification Authority", certificateType: .cer, bundle: bundle)

    //Сертификат для стендов ИФТ
    public static let ift: Certificate? = Certificate(name: "ift_pem_thawte_sslwebserver", certificateType: .der, bundle: bundle)
    
    //Сертификат для стендов ПСИ
    public static let psi: Certificate? = Certificate(name: "psi_pem_thawte_sslwebserver", certificateType: .der, bundle: bundle)

    //Сертификат для стендов ПРОМ
    public static let prom: Certificate? = Certificate(name: "thawte_ev_ssl_ca_g3", certificateType: .der, bundle: bundle)
    
    //Сертификат для тестовых стендов (Самоподписанный)
    public static let testRoot: Certificate? = Certificate(name: "test_root_ca_2", certificateType: .der, bundle: bundle)

    //Выпускающий сертификат для тестовых стендово (Самоподписанный)
    public static let testIssuing: Certificate? = Certificate(name: "sberbank_test_issuing_ca_2", certificateType: .der, bundle: bundle)



}
