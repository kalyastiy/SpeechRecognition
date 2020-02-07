//
//  Created by Daniil Kalintsev on 25/10/2019.
//  Copyright © 2019 Sberbank. All rights reserved.
//

import Foundation

/// Фабрика по созданию объектов потокового воспроизведения аудио данных.
struct StreamPlayerFactory: StreamPlayerInstantiating {

	func player(with format: AudioFormat) throws -> StreamablePlayer {
		return try AudioStreamPlayer(format: format)
	}
}
