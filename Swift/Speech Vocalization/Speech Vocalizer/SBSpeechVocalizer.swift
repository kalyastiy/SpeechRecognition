//
//  Created by Daniil Kalintsev on 17/10/2019.
//  Copyright © 2019 Sberbank. All rights reserved.
//

import Foundation

/// Объект-озвучивания, использующий технологии Сбербанка (VPS-сервис).
public final class SBSpeechVocalizer {

	// MARK: - Common Properties

	public var isRunning: Bool {
		return player?.isRunning ?? false
	}

	/// Сессия VPS, из которой получаются аудиоданные.
	public var processingSession: ProcessingSession? {
		didSet {
			processingSession?.vocalizationSessionDelegate = self
		}
	}

	private var player: StreamablePlayer?

	// MARK: - <SpeechVocalizing>

	public weak var delegate: SpeechVocalizerDelegate?

	// MARK: - Initializers

	public convenience init() {
		self.init(streamPlayerFactory: StreamPlayerFactory())
	}

	init(streamPlayerFactory: StreamPlayerInstantiating) {
		self.streamPlayerFactory = streamPlayerFactory
	}

	private let streamPlayerFactory: StreamPlayerInstantiating
}

/// Фабрика по созданию объекта потокового воспроизведения аудио.
protocol StreamPlayerInstantiating {

	/// Создание объекта плеера.
	///
	/// - Parameter format: Формат для инициализации плеера.
	/// - Returns: Плеер, настроенный на работу с входным форматом.
	/// - Throws: Ошибки инициализации плеера (Прим. некорректный формат
	///			  или недоступность устройства вывода).
	func player(with format: AudioFormat) throws -> StreamablePlayer
}

/// MARK: - <SpeechVocalizing>
extension SBSpeechVocalizer: SpeechVocalizing {

	public func start() throws {
		assert(player != nil, "Player has not yet initialized with format")
		try player?.start()
	}

	public func pause() {
		assert(player != nil, "Player has not yet initialized with format")
		try? player?.pause()
	}

	public func stop() {
		assert(player != nil, "Player has not yet initialized with format")
		try? player?.stop()
	}
}

/// MARK: - <VocalizationSessionDelegate>
extension SBSpeechVocalizer: VocalizationSessionDelegate {
    public func vocalizationSession(_ session: SessionProtocol, didReceiveError error: Error) {
        print("ERROR: \(error.localizedDescription)")
    }
    
    public func vocalizationSessionDidFinish(_ session: SessionProtocol, canceled cancelled: Bool) {
        print("CANCELED")
    }

	// MARK: - Methods

	public func vocalizationSession(
		_ session: SessionProtocol,
        didReceivePartitialVoiceResut data: Data
	) {
        guard !data.isEmpty else { return }
       do {
           try instantiatePlayerIfNeeded(from: data)
           let processingData = WAVHeader.removeWavHeaderIfNeeded(from: data)
           player?.add(processingData)
       } catch {
           delegate?.speechVocalizer(self, didFailedWithError: error)
       }
	}

	private func instantiatePlayerIfNeeded(from data: Data) throws {
		guard player == nil else { return }
		let header = try WAVHeader(data: data)
		let format = self.format(from: header)
		player = try streamPlayerFactory.player(with: format)
		player?.delegate = self
		try player?.start()
	}

	private func format(from header: WAVHeader) -> AudioFormat {
		return AudioFormat(
			sampleRate: Float64(header.sampleRate),
			channelsPerFrame: UInt32(header.numChannels),
			bitsPerChanel: UInt32(header.bitsPerSample)
		)
	}
}

/// MARK: - <PCMChunkedAudioPlayerDelegate>
extension SBSpeechVocalizer: AudioPlayerDelegate {

	func audioStreamPlayer(_ player: AudioPlayer, didFailWithError error: Error) {
		delegate?.speechVocalizer(self, didFailedWithError: error)
	}
}
