//
//  Transport.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 21.10.2019.
//

import Foundation

//Класс для передачи сообщений (Message).
//- note: Протокол Transport аобстрагирует конкретный механизм передачи данных
protocol Transport: AnyObject {
    
    //Делагат класса Transport
    var delegate: TransportDelegate? { get set }
    
    //Метод для отправки абстрактного сообщения
    func send(message: Message)
}


//Протокол делегата Transport
protocol TransportDelegate: AnyObject {
    
    //Вызвается при установке соединения и начале отправки сообщений
    func estabilshedConnection()
    
    //Вызывается при поетере соединения
    func lostConnection(with error: Error?)
    
    //Вызывается при получении сообщения
    func received(message: Message)
}
