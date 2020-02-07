//
//  Created by Daniil Kalintsev on 13/11/2019.
//  Copyright © 2019 Sberbank. All rights reserved.
//

import Foundation

///
/// Фабрика по созданию аудио пакетов, позволяющая производить их предварительную нормализацию.
///
final class AudioPacketFactory {

	// MARK: - Properties

	private let packetSize: Int
	private var previousRemainder: Data?

	// MARK: - Initialization

	init(packetSize: Int) {
		self.packetSize = packetSize
	}

	// MARK: - Methods

	/// Генерация пакетов с их предварительной нормализацией.
	/// - Note: Длина проигрываемых данных должна быть всегда четной, т.к. один Sample аудио
	/// 		содержится в 2 байтах данных. Если не учитывать этот момент, то появится белый шум
	///			при проигрывании.
	/// - Parameter data: Данные для деления на чанки и нормализации.
	/// - Returns: Нормализованный набор пакетов данных для проигрывания плеером.
	func packets(from data: Data) -> [PayloadAudioPacket] {
		var data = data
		addPreviousDataRemainderIfNeeded(&data)
		normalizeDataIfNeeded(&data)
		return PayloadAudioPacket.packets(
			from: data,
			splitBySize: packetSize
		)
	}

	private func addPreviousDataRemainderIfNeeded(_ data: inout Data) {
		guard let lastRemainder = previousRemainder else { return }
		data = lastRemainder + data
		self.previousRemainder = nil
	}

	private func normalizeDataIfNeeded(_ data: inout Data) {
		guard data.count % 2 != 0 else { return }
		previousRemainder = data.dropLast()
	}
}

/// MARK: - Data Normalization
private extension Data {

	mutating func dropLast() -> Data {
		let last = self.last
		self = subdata(in: 0..<count - 1)
		return last
	}

	var last: Data {
		return subdata(in: count - 1..<count)
	}
}
