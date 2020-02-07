//
//  WAVHeader.swift
//  AudioQueuePlayer
//
//  Created by Daniil Kalintsev on 09/10/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import Foundation

///
/// Заголовок WAV формата.
///
struct WAVHeader {

	// MARK: - Types

	/// Ошибки серилизации исходных данных в заголовок.
	///
	/// - invalidHeaderSize: Неверный размер заголовка.
	/// - invalidHeaderFormat: Неверный формат заголовка.
	enum Error: Swift.Error {
		case invalidHeaderSize
		case invalidHeaderFormat
		case unableToParseStringFromField(Field)
	}

	/// Поля заголовка WAV файла.
	/// - note: Спецификация формата WAV.
	/// [1] http://unusedino.de/ec64/technical/formats/wav.html
	/// [2] http://soundfile.sapp.org/doc/WaveFormat/
	enum Field {
		case chunkID
		case chunkSize
		case format
		case subchunk1ID
		case subchunk1Size
		case audioFormat
		case numChannels
		case sampleRate
		case byteRate
		case blockAlign
		case bitsPerSample
		case subchunk2ID
		case subchunk2Size

		/// Диапазон в поля в заголовке.
		var range: Range<Data.Index> {
			switch self {
			case .chunkID: return 0..<4
			case .chunkSize: return 4..<8
			case .format: return 8..<12
			case .subchunk1ID: return 12..<16
			case .subchunk1Size: return 16..<20
			case .audioFormat: return 20..<22
			case .numChannels: return 22..<24
			case .sampleRate: return 24..<28
			case .byteRate: return 28..<32
			case .blockAlign: return 32..<34
			case .bitsPerSample: return 34..<36
			case .subchunk2ID: return 36..<40
			case .subchunk2Size: return 40..<44
			}
		}
	}

	// MARK: - Constants

	private static let headerSize = 44

	// MARK: - Initializers

	/// Инициализация заголовка из исходных данных.
	///
	/// - Parameter data: Исходные данные.
	/// - Throws: Ошибки, связанные с сериализацией данных в заголовок.
	init(data: Data) throws {
		guard data.count >= WAVHeader.headerSize else { throw Error.invalidHeaderSize }
		guard Selff.isWAV(data: data) else { throw Error.invalidHeaderFormat }

		chunkID = try Selff.extractField(.chunkID, from: data)
		chunkSize = Selff.extractField(.chunkSize, from: data)
		format = try Selff.extractField(.format, from: data)
		subchunk1ID = try Selff.extractField(.subchunk1ID, from: data)
		subchunk1Size = Selff.extractField(.subchunk1Size, from: data)
		audioFormat = Selff.extractField(.audioFormat, from: data)
		numChannels = Selff.extractField(.numChannels, from: data)
		sampleRate = Selff.extractField(.sampleRate, from: data)
		byteRate = Selff.extractField(.byteRate, from: data)
		blockAlign = Selff.extractField(.blockAlign, from: data)
		bitsPerSample = Selff.extractField(.bitsPerSample, from: data)
		subchunk2ID = try Selff.extractField(.subchunk2ID, from: data)
		subchunk2Size = Selff.extractField(.subchunk2Size, from: data)
	}
	private typealias Selff = WAVHeader

	let chunkID: String
	let chunkSize: UInt16
	let format: String
	let subchunk1ID: String
	let subchunk1Size: UInt16
	let audioFormat: UInt8
	let numChannels: UInt8
	let sampleRate: UInt16
	let byteRate: UInt16
	let blockAlign: UInt8
	let bitsPerSample: UInt8
	let subchunk2ID: String
	let subchunk2Size: UInt16

	// MARK: - Verification

	/// Базовая проверка данных на соответствие заголовку.
	/// - Important: Проверка корректности данных в заголовке не проверяется.
	///
	/// - Parameter data: Исходные данны.
	/// - Returns: True в случае соответствия.
	static func isWAV(data: Data) -> Bool {
        let riffHeaderSize = 12

        guard data.count >= riffHeaderSize else { return false }

		let riffChunkID = try? extractField(.chunkID, from: data)
		guard riffChunkID == "RIFF" else { return false }

		let riffFormat = try? extractField(.format, from: data)
		guard riffFormat == "WAVE" else { return false }

        return true
    }

	private static func extractField<T: UnsignedInteger>(_ field: Field, from data: Data) -> T {
		return data
			.subdata(in: field.range)
			.withUnsafeBytes { $0.load(as: T.self) }
	}

	private static func extractField(_ field: Field, from data: Data) throws -> String {
		guard let result = String(
			data: data.subdata(in: field.range),
			encoding: String.Encoding.utf8
		) else {
			throw Error.unableToParseStringFromField(field)
		}
		return result
	}

	// MARK: - Fixing

	static func removeWavHeaderIfNeeded(from data: Data) -> Data {
		guard
			data.count >= WAVHeader.headerSize,
			isWAV(data: data)
		else { return data }
		return data.subdata(in: WAVHeader.headerSize..<data.count)
	}
}
