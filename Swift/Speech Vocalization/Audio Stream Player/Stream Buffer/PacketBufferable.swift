//
//  Created by Daniil Kalintsev on 24/10/2019.
//  Copyright © 2019 Sberbank. All rights reserved.
//

import Foundation

protocol PacketBufferable {

	var capacity: Int { get }
	func add(_ packets: [AudioPacket])
	func next() -> AudioPacket?
	func nextPacketSize() -> Int?
}
