//
//  String+HTML.swift
//  mfp6
//
//  Created by Nikolay Lukyanchikov on 23.10.2019.
//

import Foundation


//Расширение по работе со стоками, содержащими HTML

extension String {
    
    //Замена экранированных в HTML символов.
    //-returns: Разэкранированная строка, с корректными символами ASCII.
    public func removeHTMLEntities() -> String {
        var copy = self
        var cursorPosition = startIndex
        while let delimiterRange = range(of: "&", range: cursorPosition ..< endIndex) {
            guard let semicolonRange = range(of: ";", range: delimiterRange.upperBound ..< endIndex) else {
                cursorPosition = delimiterRange.upperBound
                break
            }
            
            let escapableRange = delimiterRange.upperBound ..< semicolonRange.lowerBound
            let replacebleRange = delimiterRange.lowerBound ..< semicolonRange.upperBound
            let escapableContent = self[escapableRange]
            
            if let unescapedCharacter = HTMLStringMappings.htmlSymbols[String(escapableContent)] {
                copy.replaceSubrange(replacebleRange, with: unescapedCharacter)
                cursorPosition = self.index(delimiterRange.lowerBound, offsetBy: unescapedCharacter.count)
            } else {
                cursorPosition = semicolonRange.upperBound
            }
        }
        
        return copy
    }
}


//Расширения по разэкранированию специальных символов

extension String {
    
    //Функция удаления символов экранирования из строки
    //-returns: Новая сттрока, в которой отсуствуют символы экранирования для специальных символов.
    public func unescapeSpecialCharacters() -> String {
        let entities = ["\0", "\t", "\n", "\r", "\"", "\'", "\\"]
        var current = self
        for entity in entities {
            let descriptionCharacters = entity.debugDescription.dropFirst().dropLast()
            let description = String(descriptionCharacters)
            current = current.replacingOccurrences(of: description, with: entity)
        }
        return current
    }
}



private enum HTMLStringMappings {
    
    static let htmlSymbols: [String: String] = [
        "lt": "\u{3c}", //<
        "gt": "\u{3e}", //>
        "amp": "\u{26}", //&
        "quot": "\u{22}", //"
        "apos": "\u{27}" //'
    ]
}
