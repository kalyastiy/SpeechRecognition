//
//  Created by Daniil Kalintsev on 28/10/2019.
//  Copyright © 2019 Sberbank. All rights reserved.
//

import Foundation

/// Пакет с аудиоданными.
struct PayloadAudioPacket: AudioPacket, Equatable {

	private(set) var payloadData = Data()

	/// Инициализация пакета сырыми адуиоданными для последующего проигрывания плеером.
	///
	/// - Parameter payloadData: RAW аудиоданные.
	init(payloadData: Data) {
		self.payloadData = payloadData
	}

	/// Создание набора пакетов из данных, разделенных на пакеты фиксированной длины.
	///
	/// - Parameters:
	///   - data: RAW аудиоданные.
	///   - size: Размер одного пакта.
	/// - Returns: Массива пакетов из разделенных данных.
	static func packets(from data: Data, splitBySize size: Int) -> [PayloadAudioPacket] {
		var offset: Int = 0
		var packets = [PayloadAudioPacket]()
		while offset + size < data.count {
			let packet = PayloadAudioPacket(payloadData: data.subdata(in: offset..<offset + size))
			packets.append(packet)
			offset += size
		}
		let remainder = data.subdata(in: offset..<data.count)
		if !remainder.isEmpty {
			packets.append(PayloadAudioPacket(payloadData: remainder))
		}

		return packets
	}
}
