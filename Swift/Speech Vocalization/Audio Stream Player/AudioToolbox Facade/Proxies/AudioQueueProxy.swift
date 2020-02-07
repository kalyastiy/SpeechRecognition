//
//  Created by Daniil Kalintsev on 18/10/2019.
//  Copyright © 2019 Sberbank. All rights reserved.
//

import AudioToolbox
import Foundation

// swiftlint:disable identifier_name
/// Протокол по работе с AudioToolbox для обеспечения возможности тестирования вызовов
/// глобальных функций фреймворка.
protocol AudioQueueProxy {

	func AudioQueueNewOutputWithDispatchQueue(
		_ outAQ: UnsafeMutablePointer<AudioQueueRef?>,
		_ inFormat: UnsafePointer<AudioStreamBasicDescription>,
		_ inFlags: UInt32,
		_ inCallbackDispatchQueue: DispatchQueue,
		_ inCallbackBlock: @escaping AudioQueueOutputCallbackBlock
	) -> OSStatus

	func AudioQueueDispose(
		_ inAQ: AudioQueueRef,
		_ inImmediate: Bool
	) -> OSStatus

	func AudioQueueStart(
		_ inAQ: AudioQueueRef,
		_ inStartTime: UnsafePointer<AudioTimeStamp>?
	) -> OSStatus

	func AudioQueuePause(_ inAQ: AudioQueueRef) -> OSStatus

	func AudioQueueStop(
		_ inAQ: AudioQueueRef,
		_ inImmediate: Bool
	) -> OSStatus

	func AudioQueueReset(_ inAQ: AudioQueueRef) -> OSStatus

	func AudioQueueAllocateBuffer(
		_ inAQ: AudioQueueRef,
		_ inBufferByteSize: UInt32,
		_ outBuffer: UnsafeMutablePointer<AudioQueueBufferRef?>
	) -> OSStatus

	func AudioQueueEnqueueBuffer(
		_ inAQ: AudioQueueRef,
		_ inBuffer: AudioQueueBufferRef,
		_ inNumPacketDescs: UInt32,
		_ inPacketDescs: UnsafePointer<AudioStreamPacketDescription>?
	) -> OSStatus
}

/// Объект проксирования системных вызовов по работе с AudioToolbox.
struct SystemAudioQueueProxy: AudioQueueProxy {

	func AudioQueueNewOutputWithDispatchQueue(
		_ outAQ: UnsafeMutablePointer<AudioQueueRef?>,
		_ inFormat: UnsafePointer<AudioStreamBasicDescription>,
		_ inFlags: UInt32,
		_ inCallbackDispatchQueue: DispatchQueue,
		_ inCallbackBlock: @escaping AudioQueueOutputCallbackBlock
	) -> OSStatus {
		return AudioToolbox.AudioQueueNewOutputWithDispatchQueue(
			outAQ,
			inFormat,
			inFlags,
			inCallbackDispatchQueue,
			inCallbackBlock
		)
	}

	func AudioQueueDispose(
		_ inAQ: AudioQueueRef,
		_ inImmediate: Bool
	) -> OSStatus {
		return AudioToolbox.AudioQueueDispose(
			inAQ,
			inImmediate
		)
	}

	func AudioQueueStart(
		_ inAQ: AudioQueueRef,
		_ inStartTime: UnsafePointer<AudioTimeStamp>?
	) -> OSStatus {
		return AudioToolbox.AudioQueueStart(
			inAQ,
			inStartTime
		)
	}

	func AudioQueuePause(_ inAQ: AudioQueueRef) -> OSStatus {
		return AudioToolbox.AudioQueuePause(inAQ)
	}

	func AudioQueueStop(
		_ inAQ: AudioQueueRef,
		_ inImmediate: Bool
	) -> OSStatus {
		return AudioToolbox.AudioQueueStop(inAQ, inImmediate)
	}

	func AudioQueueReset(_ inAQ: AudioQueueRef) -> OSStatus {
		return AudioToolbox.AudioQueueReset(inAQ)
	}

	func AudioQueueAllocateBuffer(
		_ inAQ: AudioQueueRef,
		_ inBufferByteSize: UInt32,
		_ outBuffer: UnsafeMutablePointer<AudioQueueBufferRef?>
	) -> OSStatus {
		return AudioToolbox.AudioQueueAllocateBuffer(
			inAQ,
			inBufferByteSize,
			outBuffer
		)
	}

	func AudioQueueEnqueueBuffer(
		_ inAQ: AudioQueueRef,
		_ inBuffer: AudioQueueBufferRef,
		_ inNumPacketDescs: UInt32,
		_ inPacketDescs: UnsafePointer<AudioStreamPacketDescription>?
	) -> OSStatus {
		return AudioToolbox.AudioQueueEnqueueBuffer(
			inAQ,
			inBuffer,
			inNumPacketDescs,
			inPacketDescs
		)
	}
}
// swiftlint:enable identifier_name
