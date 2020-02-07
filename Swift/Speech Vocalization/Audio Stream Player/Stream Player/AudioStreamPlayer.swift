//
//  Created by Daniil Kalintsev on 09/10/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import Foundation

final class AudioStreamPlayer {

	// MARK: - Types

	private enum State {
		case notRunning
		case running
		case paused
		case stoped
	}

	// MARK: - Constants

	private enum Constants {
		static let packetSize: Int = 128
	}

	// MARK: - <StreamablePlayer>

	weak var delegate: AudioPlayerDelegate?

	// MARK: - Common

	var isRunning: Bool { return state == .running }
	private var state: State = .notRunning

	/// Базовая инициализация плеера по аудиоформату.
	///
	/// - Parameter format: Формат аудиоданных для проигрывания.
	/// - Throws: Ошибки инициализации буфферов.
	convenience init(format: AudioFormat) throws {
		try self.init(
			format: format,
			bufferSize: 2048,
			packetSize: Constants.packetSize,
			streamBuffer: StreamedAudioPacketBuffer(capacity: 4096),
			audioQueue: try SystemAudioQueue(format: format.streamFormat)
		)
	}

	/// Полная инициализация плеера со всеми необходимыми зависимостями.
	///
	/// - Parameters:
	///   - format: Формат проигрываемых данных.
	///   - bufferSize: Размер буффера для пакетов.
	///   - streamBuffer: Буффер для накполнения данных.
	///   - audioQueue: Очередь для проигрывания.
	/// - Throws: Ошибки инициализации буфферов для плеера.
	init(
		format: AudioFormat,
		bufferSize: Int,
		packetSize: Int,
		streamBuffer: PacketBufferable,
		audioQueue: AudioQueue
	) throws {
		self.format = format
		self.bufferSize = bufferSize
		self.packetSize = packetSize
		self.packetFactory = AudioPacketFactory(packetSize: packetSize)
		self.packetBuffer = streamBuffer
		self.audioQueue = audioQueue
		self.audioQueue.delegate = self
		try loadBuffers()
	}

	private(set) var format: AudioFormat
	let bufferSize: Int
	private var packetBuffer: PacketBufferable
	private var audioQueue: AudioQueue
	let packetSize: Int
	private let packetFactory: AudioPacketFactory

	private func loadBuffers() throws {
		let buffersCount = 3
		try (0..<buffersCount).forEach { _ in
			let buffer = try audioQueue.buffer(size: bufferSize)
			try audioQueue.enqueue(buffer: buffer)
		}
	}
}

/// MARK: - <StreamablePlayer>
extension AudioStreamPlayer: StreamablePlayer {

	func start() throws {
		guard state == .notRunning || state == .paused else { return }
		try audioQueue.start()
		state = .running
	}

	func stop() throws {
		guard state != .stoped else { return }
		try audioQueue.stop()
		state = .stoped
	}

	func pause() throws {
		guard state == .running else { return }
		try audioQueue.pause()
		state = .paused
	}

	func add(_ data: Data) {
		packetBuffer.add(packetFactory.packets(from: data))
	}
}

// MARK: - <AudioQueueDelegate>
extension AudioStreamPlayer: AudioQueueDelegate {

	func audioQueue(
		_ queue: AudioQueue,
		didEnqeueBuffer buffer: AudioBuffer
	) {
		var offset: Int = 0
		buffer.clean()
		while
			let nextPacketSize = packetBuffer.nextPacketSize(),
			buffer.hasSpace(for: nextPacketSize, atOffset: offset),
			let nextPacket = packetBuffer.next()
		{
			buffer.fill(with: nextPacket, offset: offset)
			offset += nextPacket.payloadData.count
		}
		tryToEnqueueBuffer(buffer, in: queue)
	}

	private func tryToEnqueueBuffer(_ buffer: AudioBuffer, in queue: AudioQueue) {
		do {
			try queue.enqueue(buffer: buffer)
		} catch {
			delegate?.audioStreamPlayer(self, didFailWithError: error)
		}
	}
}
