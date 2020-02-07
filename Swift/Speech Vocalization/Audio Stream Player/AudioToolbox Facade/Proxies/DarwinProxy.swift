//
//  Created by Daniil Kalintsev on 23/10/2019.
//  Copyright © 2019 Sberbank. All rights reserved.
//

import Darwin
import Foundation

// swiftlint:disable identifier_name
/// Протокол по работе с Darwin для обеспечения возможности тестирования вызовов
/// глобальных функций фреймворка.
protocol DarwinProxy {
	func memset(_ _b: UnsafeMutableRawPointer!, _ _c: Int32, _ _len: Int)
}

/// Объект проксирования системных вызовов по работе с Darwin.
struct SystemDarwinProxy: DarwinProxy {

	func memset(
		_ _b: UnsafeMutableRawPointer!,
		_ _c: Int32,
		_ _len: Int
	) {
		Darwin.memset(
			_b,
			_c,
			_len
		)
	}
}
// swiftlint:enable identifier_name
