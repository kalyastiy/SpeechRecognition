//
//  Created by Daniil Kalintsev on 10/10/2019.
//  Copyright © 2019 Sberbank. All rights reserved.
//

import AudioToolbox
import Foundation

/// Формат аудиоданных для воспроизведения.
struct AudioFormat {

	// MARK: - Properties

	/// Внутренний формат данных для потока аудио в AudioToolbox.
	let streamFormat: AudioStreamBasicDescription

	// MARK: - Initializers

	/// Базовая инициализация формата аудиоданных.
	///
	/// - Parameters:
	///   - sampleRate: Частота дискретизации потока.
	///   - channelsPerFrame: Количество аудиоканалов.
	///   - bitsPerChanel: Количество бит для одного фрагмента звука.
	init(
		sampleRate: Float64,
		channelsPerFrame: UInt32,
		bitsPerChanel: UInt32
	) {
		var streamFormat = AudioStreamBasicDescription()
		streamFormat.mSampleRate = sampleRate
		streamFormat.mFormatID = kAudioFormatLinearPCM
		streamFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked
		streamFormat.mBitsPerChannel = bitsPerChanel
		streamFormat.mChannelsPerFrame = channelsPerFrame
		streamFormat.mBytesPerPacket = (bitsPerChanel / UInt32(MemoryLayout<Int>.size)) * channelsPerFrame
		streamFormat.mBytesPerFrame = (bitsPerChanel / UInt32(MemoryLayout<Int>.size)) * channelsPerFrame
		streamFormat.mFramesPerPacket = 1
		streamFormat.mReserved = 0
		self.streamFormat = streamFormat
	}
}
