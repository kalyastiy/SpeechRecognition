//
//  Created by Daniil Kalintsev on 28/10/2019.
//  Copyright © 2019 Sberbank. All rights reserved.
//

import Foundation

/// Плеер с возможностью проигрывания аудио потока.
protocol StreamablePlayer: AudioPlayer {

	/// Добавление новой последовательности аудиоданных для проигрывания.
	///
	/// - Parameter data: Новые аудиоданные.
	func add(_ data: Data)
}
