//
//  Created by Daniil Kalintsev on 23/10/2019.
//  Copyright © 2019 Sberbank. All rights reserved.
//

import AudioToolbox
import Foundation

/// Аудиобуффер, позволяющий:
/// - Задавать максимальную вместимость буффера.
/// - Заполнять себя новыми аудиоданными переменной длины.
/// - Очищать буффер.
protocol AudioBuffer {

	// MARK: - Properties

	var ref: AudioQueueBufferRef { get }
	var capacity: Int { get }
	var payloadSize: Int { get set }

	// MARK: - Methods

	func clean()

	/// Наполнить буффер новым пакетом данных с указанными смещением.
	///
	/// - Parameters:
	///   - packet: Пакет данных для наполнения буффера.
	///   - offset: Смещение в адресном пространстве буффера для заполнения новым пакетом.
	func fill(
		with packet: AudioPacket,
		offset: Int
	)

	/// Проверка вместимости нового пакета данных с заданным размером в буффера
	/// по указанному смещению.
	///
	/// - Parameters:
	///   - size: Размер данных для последующего заполнения.
	///   - offset: Смещение для новый данных в буффере.
	/// - Returns: True, если буффер может вместить в себя новые данные.
	func hasSpace(
		for size: Int,
		atOffset offset: Int
	) -> Bool
}
