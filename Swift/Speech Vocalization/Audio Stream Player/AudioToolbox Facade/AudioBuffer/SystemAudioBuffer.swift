//
//  Created by Daniil Kalintsev on 10/10/2019.
//  Copyright © 2019 Sberbank. All rights reserved.
//

import AudioToolbox
import Foundation

/// Буффер по накоплению аудиоданных с потока.
final class SystemAudioBuffer {

	// MARK: - Types

	/// Ошибки, возникающие в ходе работы буффера.
	///
	/// - couldNotInitializeBuffer: Ошибка инициализации буффера. Никогда не произойдет из-за того,
	/// что вызов низкоуровнего API по работе с указателями и так проверяется на ошибку OS статуса.
	enum AudioBufferError: Swift.Error {
		case couldNotInitializeBuffer
	}
	private typealias Error = AudioBufferError

	// MARK: - Initialization

	/// Инициализация пустого буффера определенного размера для заданной AudioQueue.
	///
	/// - Parameters:
	///   - queue: Очередь, к которой будет привязан буффер.
	///   - size: Размер буффера.
	///   - audioQueueProxy: Прокси-объект для работы с AudioToolbox API.
	///   - darwinProxy: Прокси-объект для работы с Darwin API.
	/// - Throws: Ошибки инициализации буффера AudioToolbox.
	convenience init(
		queue: AudioQueueRef,
		size: Int,
		audioQueueProxy: AudioQueueProxy = SystemAudioQueueProxy(),
		darwinProxy: DarwinProxy = SystemDarwinProxy()
	) throws {
		var ref: AudioQueueBufferRef?
		try CheckError(
			audioQueueProxy.AudioQueueAllocateBuffer(
				queue,
				UInt32(size),
				&ref
			),
			"""
			Couldn't allocate audio buffer for queue: \(queue) \
			with size: \(size)
			"""
		)
		guard let buffer = ref else { throw Error.couldNotInitializeBuffer }
		self.init(buffer: buffer, darwinProxy: darwinProxy)
		clean()
	}

	/// Базовая инициализация буффера, принимающая на вход Raw буффера AudioToolbox.
	///
	/// - Parameters:
	///   - buffer: Буффер AudioToolbox, который будет декорирован.
	///   - darwinProxy: Прокси-объект для работы с Darwin API.
	init(
		buffer: AudioQueueBufferRef,
		darwinProxy: DarwinProxy = SystemDarwinProxy()
	) {
		self.ref = buffer
		self.darwin = darwinProxy
	}

	private(set) var ref: AudioQueueBufferRef
	private let darwin: DarwinProxy
}

// MARK: - <AudioBuffering>
extension SystemAudioBuffer: AudioBuffer {

	// MARK: - Properties

	var capacity: Int {
		return Int(ref.pointee.mAudioDataBytesCapacity)
	}

	var payloadSize: Int {
		get { return Int(ref.pointee.mAudioDataByteSize) }
		set { ref.pointee.mAudioDataByteSize = UInt32(newValue) }
	}

	var data: Data {
		return Data(
			buffer: UnsafeBufferPointer(
				start: ref.pointee.mAudioData.assumingMemoryBound(to: UInt8.self),
				count: Int(payloadSize)
			)
		)
	}

	// MARK: - Methods

	func clean() {
		darwin.memset(
			ref.pointee.mAudioData,
			0,
			Int(ref.pointee.mAudioDataBytesCapacity)
		)
		payloadSize = Int(ref.pointee.mAudioDataBytesCapacity)
	}

	func fill(
		with packet: AudioPacket,
		offset: Int
	) {
		let packetSize = packet.payloadData.count
		packet.payloadData.withUnsafeBytes {
			ref.pointee.mAudioData
				.advanced(by: offset)
				.copyMemory(from: $0, byteCount: packetSize)
		}
		payloadSize = offset + packetSize
	}

	func hasSpace(
		for size: Int,
		atOffset offset: Int
	) -> Bool {
		return offset + size <= capacity
	}
}
