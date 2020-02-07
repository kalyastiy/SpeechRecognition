//
//  Created by Daniil Kalintsev on 10/10/2019.
//  Copyright © 2019 Sberbank. All rights reserved.
//

import AudioToolbox
import Foundation

///
/// Объектно-ориентированная обвязка над системной AudioQueue из AudioToolbox.
/// - Note: Позволяет управлять системной очередью с помощью объектно-ориентированных
///			технологий, тестировать взаимодействие с очередью, а также получать понятные
///			сообщения об ошибках.
final class SystemAudioQueue {

	// MARK: - Types

	/// Ошибки, возникающие при работе с очередью.
	///
	/// - queueHasAlreadyDisposed: Очередь уже освобождена и требует реинициализации.
	enum AudioQueueError: Swift.Error {
		case queueHasAlreadyDisposed
	}
	private typealias Error = AudioQueueError

	// MARK: - Properties

	weak var delegate: AudioQueueDelegate?

	private var queue: AudioQueueRef?
	private let audioQueueProxy: AudioQueueProxy
	private let procceedQueue: DispatchQueue
	private let audioBufferFactory: AudioBufferInstantiating

	private static let procceedQueue = DispatchQueue(label: "AudioQueueEnqueingDispatchQueue")

	// MARK: - Initializers

	convenience init(format: AudioStreamBasicDescription) throws {
		try self.init(
			format: format,
			procceedQueue: SystemAudioQueue.procceedQueue,
			audioQueueProxy: SystemAudioQueueProxy(),
			audioBufferFactory: AudioBufferFactory()
		)
	}

	init(
		format: AudioStreamBasicDescription,
		procceedQueue: DispatchQueue,
		audioQueueProxy: AudioQueueProxy,
		audioBufferFactory: AudioBufferInstantiating
	) throws {
		self.audioQueueProxy = audioQueueProxy
		self.procceedQueue = procceedQueue
		self.audioBufferFactory = audioBufferFactory
		queue = try queue(format: format)
	}

	private func queue(format: AudioStreamBasicDescription) throws -> AudioQueueRef {
		var inFormat = format
		var queue: AudioQueueRef! = nil
		let emptyFlags: UInt32 = 0
		try CheckError(
			audioQueueProxy.AudioQueueNewOutputWithDispatchQueue(
				&queue,
				&inFormat,
				emptyFlags,
				procceedQueue
			) { [weak self] in self?.handleOutputCallback(bufferRef: $1) },
			"""
			Couldn't initialize audio queue with format: \(inFormat) \
			for dispatch queue: \(procceedQueue)
			"""
		)
		return queue
	}

	private func handleOutputCallback(
		bufferRef: AudioQueueBufferRef
	) {
		let buffer = SystemAudioBuffer(buffer: bufferRef)
		if let delegate = delegate {
			delegate.audioQueue(self, didEnqeueBuffer: buffer)
		} else {
			buffer.clean()
		}
	}

	deinit {
		try? reset()
		try? free()
	}

	private func reset() throws {
		let queue = try unwrapQueue()
		try CheckError(
			audioQueueProxy.AudioQueueReset(
				queue
			),
			"Couldn't reset audio queue: \(queue)"
		)
	}

	private func free() throws {
		let queue = try unwrapQueue()
		let immediatley = true
		try CheckError(
			audioQueueProxy.AudioQueueDispose(
				queue,
				immediatley
			),
			"""
			Couldn't dispose audio queue: \(queue) \
			immediatley: \(immediatley)
			"""
		)
	}
}

/// MARK: - <AudioQueue>
extension SystemAudioQueue: AudioQueue {

	func buffer(size: Int) throws -> AudioBuffer {
		return try audioBufferFactory.buffer(for: try unwrapQueue(), size: Int(size))
	}

	func start() throws {
		let queue = try unwrapQueue()
		let startImmediately: UnsafePointer<AudioTimeStamp>? = nil
		try CheckError(
			audioQueueProxy.AudioQueueStart(
				queue,
				startImmediately
			),
			"""
			Couldn't start audio queue \(queue) \
			timeStamp: \(String(describing: startImmediately))
			"""
		)
	}

	func pause() throws {
		let queue = try unwrapQueue()
		try CheckError(
			audioQueueProxy.AudioQueuePause(
				queue
			),
			"Couldn't pause audio queue: \(queue)"
		)
	}

	func stop() throws {
		let queue = try unwrapQueue()
		let immediatley = true
		try CheckError(
			audioQueueProxy.AudioQueueStop(
				queue,
				immediatley
			),
			"""
			Couldn't stop audio queue: \(queue) \
			immediatley: \(immediatley)
			"""
		)
	}

	func enqueue(buffer: AudioBuffer) throws {
		let queue = try unwrapQueue()
		let bufferToEnqueue = buffer.ref
		let numberOfPackets: UInt32 = 0 // т.к. формат PCM не подразумевает пакетов с переменным samplerate
		let packetDescriptions: UnsafePointer<AudioStreamPacketDescription>? = nil
		try CheckError(
			audioQueueProxy.AudioQueueEnqueueBuffer(
				queue,
				bufferToEnqueue,
				numberOfPackets,
				packetDescriptions
			),
			"""
			Couldn't enqueue audio buffer: \(bufferToEnqueue) \
			for queue: \(queue) \
			numberOfPackets: \(numberOfPackets) \
			packetDescriptions: \(String(describing: packetDescriptions))
			"""
		)
	}

	private func unwrapQueue() throws -> AudioQueueRef {
		guard let queue = queue else { throw Error.queueHasAlreadyDisposed }
		return queue
	}
}

protocol AudioBufferInstantiating {

	func buffer(for queue: AudioQueueRef, size: Int) throws -> AudioBuffer
}
