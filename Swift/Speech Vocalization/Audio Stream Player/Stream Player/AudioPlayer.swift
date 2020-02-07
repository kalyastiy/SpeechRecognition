//
//  Created by Daniil Kalintsev on 25/10/2019.
//  Copyright © 2019 Sberbank. All rights reserved.
//

import Foundation

/// Базовый плеер для проигрывания аудио.
protocol AudioPlayer {

	/// True в случае, когда плеер проигрывает аудио в данным момент времени.
	var isRunning: Bool { get }

	/// Делегат событий плеера.
	var delegate: AudioPlayerDelegate? { get set }

	/// Запустить проигрывание аудио.
	///
	/// - Throws: Ошибки запуска плеера.
	func start() throws

	/// Приостановка плеера с возможностью дальнейшего воспроизведения аудио.
	///
	/// - Throws: Ошибки приостановки плеера.
	func pause() throws

	/// Остановка проигрывания данных.
	/// - Important: После вызова данного метода, в дальнешем плеер не сможет проигрывать аудио.
	///
	/// - Throws: Ошибки остановки плеера.
	func stop() throws
}

/// Обработчик событий плеера.
protocol AudioPlayerDelegate: AnyObject {
	func audioStreamPlayer(_ player: AudioPlayer, didFailWithError: Error)
}
