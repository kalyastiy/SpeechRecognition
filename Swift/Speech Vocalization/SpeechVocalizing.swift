//
//  Created by Daniil Kalintsev on 17/10/2019.
//  Copyright © 2019 Sberbank. All rights reserved.
//

import Foundation

/// Протокол озвучивания сырых аудиоданных.
public protocol SpeechVocalizing {

	/// Объект, принимающий события от объекта озвучивания.
	var delegate: SpeechVocalizerDelegate? { get set }

	/// В случае true, объект озвучивания проигрывает аудиоданные в текущий момент времени.
	var isRunning: Bool { get }

	/// Начать процесс озвучивания.
	///
	/// - Note: Добавлять аудиоданны можно и до начала процесса воспроизведения.
	///
	/// - Throws: Ошибки запуска озвучивания. Например, ошибки инициализации буфера.
	func start() throws

	/// Приостановить озвучивание полученных данных.
	func pause()

	/// Остановить озвучивание данных.
	///
	///	- Note: После остановки озвучивания повтороное воспроизведение невозможно,
	/// 		т.к. все проинициализированные аудиоресурсы будут освобождены.
	func stop()
}

/// Подписчик на события объекта озвучивания.
public protocol SpeechVocalizerDelegate: AnyObject {

	/// Уведомление о запуске озвучивания накопленных и новых аудиоданных.
	///
	/// - Parameter vocalizer: Объект озвучивания, инициирующий событие.
	func speechVocalizerDidStart(_ vocalizer: SpeechVocalizing)

	/// Уведомление об остановке озвучивания аудиоданных.
	///
	/// - Parameter vocalizer: Объект озвучивания, инициирующий событие.
	func speechVocalizerDidStop(_ vocalizer: SpeechVocalizing)

	/// Уведомление о приостановке озвучивания накопленных аудиоданных.
	///
	/// - Parameter vocalizer: Объект озвучивания, инициирующий событие.
	func speechVocalizerDidPause(_ vocalizer: SpeechVocalizing)

	/// Уведомление о возникновении критической ошибки,
	/// после которой работа объекта-озвучивания невозможна.
	///
	/// - Parameters:
	///   - vocalizer: Объект озвучивания, инициирующий событие.
	///   - error: Возникшая ошибка.
	func speechVocalizer(_ vocalizer: SpeechVocalizing, didFailedWithError error: Error)
}
