//
//  Created by Daniil Kalintsev on 28/10/2019.
//  Copyright © 2019 Sberbank. All rights reserved.
//

import Foundation

/// Пустой пакет аудиоданных.
/// - Note: Требуется для предварительного заполнения буффера.
struct EmptyAudioPacket: AudioPacket, Equatable {

	let payloadData: Data
	private static let emptyPacket = EmptyAudioPacket(payloadData: Data())

	private init(payloadData: Data) {
		self.payloadData = payloadData
	}

	static func packet() -> EmptyAudioPacket {
		return emptyPacket
	}

	static func packet(for size: Int) -> EmptyAudioPacket {
		return EmptyAudioPacket(payloadData: Data(repeating: 0, count: size))
	}
}
