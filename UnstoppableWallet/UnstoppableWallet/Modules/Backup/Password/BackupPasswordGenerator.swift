import Foundation
import Security

struct BackupPasswordGenerator {
    private static let lowercase = Array("abcdefghijklmnopqrstuvwxyz")
    private static let uppercase = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    private static let digits = Array("0123456789")
    // Subset of PassphraseCharacterSet.customSymbols — excludes whitespace and quotes
    // to avoid clipboard/paste issues while staying within PassphraseValidator allowed set
    private static let symbols = Array("!@#$%+=?:;.,~*$[](){}<>\\#@|%")
    private static let alphabet = lowercase + uppercase + digits + symbols

    private static let pools: [[Character]] = [lowercase, uppercase, digits, symbols]

    static func generate(length: Int = 20) throws -> String {
        guard length >= BackupModule.minimumPassphraseLength else {
            throw GeneratorError.invalidLength
        }

        // Guarantee one character from each pool to satisfy PassphraseCharacterSet validation
        var characters: [Character] = []
        for pool in pools {
            characters.append(try randomElement(from: pool))
        }

        // Fill remaining positions from flat alphabet for maximum entropy
        let remaining = length - characters.count
        for _ in 0 ..< remaining {
            characters.append(try randomElement(from: alphabet))
        }

        // Fisher-Yates shuffle to eliminate positional bias
        return try String(shuffle(characters))
    }

    // MARK: - Private

    private static func randomElement(from array: [Character]) throws -> Character {
        array[try secureRandomIndex(upperBound: array.count)]
    }

    private static func secureRandomIndex(upperBound: Int) throws -> Int {
        // Rejection sampling eliminates modulo bias.
        // We discard values above the largest multiple of upperBound
        // that fits in UInt32, then take the remainder.
        let limit = UInt32.max - (UInt32.max % UInt32(upperBound))
        var random: UInt32 = 0
        repeat {
            var bytes = [UInt8](repeating: 0, count: 4)
            guard SecRandomCopyBytes(kSecRandomDefault, 4, &bytes) == errSecSuccess else {
                throw GeneratorError.secureRandomFailed
            }
            random = bytes.withUnsafeBytes { $0.load(as: UInt32.self) }
        } while random > limit

        return Int(random % UInt32(upperBound))
    }

    private static func shuffle(_ array: [Character]) throws -> [Character] {
        var result = array
        // Fisher-Yates: iterate from last index down to 1,
        // swap each element with a cryptographically random earlier position
        for i in stride(from: result.count - 1, through: 1, by: -1) {
            let j = try secureRandomIndex(upperBound: i + 1)
            result.swapAt(i, j)
        }
        return result
    }

    enum GeneratorError: LocalizedError {
        case invalidLength
        case secureRandomFailed

        var errorDescription: String? {
            switch self {
            case .invalidLength: return "backup.password.generator.error.invalid_length".localized
            case .secureRandomFailed: return "backup.password.generator.error.random_failed".localized
            }
        }
    }
}
