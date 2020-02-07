//
//  Created by Daniil Kalintsev on 10/10/2019.
//  Copyright © 2019 Sberbank. All rights reserved.
//

import Foundation

// swiftlint:disable:next identifier_name
func CheckError(_ error: OSStatus, _ operation: String) throws {
	guard error != noErr else { return }
	let descriptor = ErrorDescriptor(rawValue: error)
	throw NSError(
		domain: NSOSStatusErrorDomain,
		code: Int(error),
		userInfo: [
			NSLocalizedDescriptionKey: descriptor.errorDescription ?? "Unknown error"
		]
	)
}

struct ErrorDescriptor {

	var chars: [CChar]

	init(rawValue: OSStatus) {
		chars = ErrorDescriptor.charsFromStatus(rawValue)
	}

	private static func charsFromStatus(_ status: OSStatus) -> [CChar] {
		let typeByteCount = 5
		let size = MemoryLayout<OSStatus>.stride * typeByteCount

		var errorBigEndian = CFSwapInt32HostToBig(UInt32(status))
		var charArray: [CChar] = [CChar](repeating: 0, count: size)
		withUnsafeBytes(of: &errorBigEndian) { (buffer: UnsafeRawBufferPointer) in
			for (index, byte) in buffer.enumerated() {
				charArray[index + 1] = CChar(byte)
			}
		}
		return charArray
	}

	var errorDescription: String? {
		guard containsErrorDescription else { return nil }
		var chars = self.chars
		chars[0] = "\'".utf8CString[0]
		chars[5] = "\'".utf8CString[0]
		return NSString(
			bytes: chars,
			length: chars.count,
			encoding: String.Encoding.ascii.rawValue
		) as String?
	}

	private var containsErrorDescription: Bool {
		return chars[1..<4]
			.map { Int32($0) }
			.allSatisfy { isprint($0) > 0 }
	}
}
