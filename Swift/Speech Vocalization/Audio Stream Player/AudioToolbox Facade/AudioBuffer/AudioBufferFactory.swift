//
//  Created by Daniil Kalintsev on 23/10/2019.
//  Copyright © 2019 Sberbank. All rights reserved.
//

import AudioToolbox
import Foundation

struct AudioBufferFactory: AudioBufferInstantiating {

	func buffer(for queue: AudioQueueRef, size: Int) throws -> AudioBuffer {
		return try SystemAudioBuffer(queue: queue, size: size)
	}
}
