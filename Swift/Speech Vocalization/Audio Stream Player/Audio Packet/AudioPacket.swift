//
//  Created by Daniil Kalintsev on 11/10/2019.
//  Copyright © 2019 Sberbank. All rights reserved.
//

import Foundation

/// Пакет аудиоданных.
protocol AudioPacket {

	var payloadData: Data { get }
}
