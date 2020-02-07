//
//  Created by Daniil Kalintsev on 11/10/2019.
//  Copyright © 2019 Sberbank. All rights reserved.
//

import AudioToolbox
import Foundation

extension PacketBufferable {

	func add(_ packet: AudioPacket) {
		add([packet])
	}
}

final class StreamedAudioPacketBuffer {

	// MARK: - Types

	private struct Index {
		var value: Int = 0
		var max: Int

		init(max: Int) {
			self.max = max
		}

		mutating func increase() {
			value &+= 1
		}

		var normalized: Int {
			return (value &+ max) % max
		}

		static func > (lhs: Index, rhs: Index) -> Bool {
			return lhs.value > rhs.value
		}
	}

	// MARK: - Types

	private let serviceQueue = DispatchQueue(label: "StreamAudioPlayer")

	// MARK: - Properties

	let capacity: Int

	private(set) var packets: [AudioPacket]
	private var _readIndex: Index
	private var _writeIndex: Index

	var readIndex: Int {
		return Int(_readIndex.value % capacity)
	}

	var writeIndex: Int {
		return Int(_writeIndex.value % capacity)
	}

	// MARK: - Initializers

	init(capacity: Int) {
		self.capacity = capacity
		self._readIndex = Index(max: capacity)
		self._writeIndex = Index(max: capacity)
		self.packets = .init(
			repeating: EmptyAudioPacket.packet(),
			count: Int(capacity)
		)
	}
}

/// MARK: - <StreamBuffering>
extension StreamedAudioPacketBuffer: PacketBufferable {

	// MARK: - Methods

	func add(_ packets: [AudioPacket]) {
		serviceQueue.async { packets.forEach { self.handlePacket($0) } }
	}

	private func handlePacket(_ packet: AudioPacket) {
		packets[writeIndex % capacity] = packet
		_writeIndex.increase()
	}

	func next() -> AudioPacket? {
		guard let packet = currentPacket else { return nil }
		_readIndex.increase()
		return packet
	}

	func nextPacketSize() -> Int? {
		return currentPacket?.payloadData.count
	}

	private var currentPacket: AudioPacket? {
		guard hasAvailablePackets else { return nil }
		return packets[readIndex]
	}

	private var hasAvailablePackets: Bool {
		return _writeIndex > _readIndex
	}
}
