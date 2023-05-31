import Foundation
import CommonCrypto
import HsCryptoKit
import HsExtensions
import Scrypt

class BackupCryptoHelper {
    static let defaultCypher = "aes-128-ctr"
    static let defaultKdf = "scrypt"

    private static func ivData(hex: String) throws -> Data { // initial vector for AES128 must be 16 bytes
        guard hex.count == 2 * kCCKeySizeAES128 else {
            throw CodingError.ivSizeError
        }

        guard let keyData = hex.hs.hexData else {
            throw CodingError.ivDataError
        }
        return keyData
    }

    private static func cryptCTR(iv: Data, key: Data, data: Data, option: CCOperation) throws -> Data {
        let cryptorPointer = UnsafeMutablePointer<CCCryptorRef?>.allocate(capacity: 1)
        key.withUnsafeBytes { key in
            _ = try? iv.withUnsafeBytes { iv in
                let status = CCCryptorCreateWithMode(
                        option,
                        CCMode(kCCModeCTR),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCPadding(ccNoPadding),
                        iv.baseAddress!,
                        key.baseAddress!,
                        key.count,
                        nil,
                        0,
                        0,
                        0,
                        cryptorPointer
                )
                guard status == kCCSuccess else {
                    throw CodingError.cryptError
                }
            }
        }
        let cryptor: CCCryptorRef = cryptorPointer.pointee!

        var resultData = data
        let count = data.count

        _ = resultData.withUnsafeMutableBytes {
            CCCryptorUpdate(cryptor, $0.baseAddress!, count, $0.baseAddress!, count, nil)
        }

        CCCryptorRelease(cryptor)

        return Data(resultData)
    }

}

extension BackupCryptoHelper {

    public static func generateInitialVector(len: Int = 16) -> Data {
        Data(Array(0..<len).map { _ in UInt8.random(in: UInt8.min...UInt8.max) })
    }

    public static func scrypt(pass: Data, kdf: KdfParams) throws -> Data {
        try Data(Scrypt.scrypt(password: pass.bytes, salt: kdf.salt.bytes, length: kdf.dklen, N: kdf.n, r: kdf.r, p: kdf.p))
    }

    public static func AES128(operation: Operation, ivHex: String, pass: String, message: Data, kdf: KdfParams) throws -> Data {
        do {
            let key = try BackupCryptoHelper.scrypt(
                    pass: pass.hs.data,
                    kdf: kdf)
            let ivData = try ivData(hex: ivHex)

            return try cryptCTR(iv: ivData, key: key, data: message, option: operation.ccValue)
        } catch {
            if error is ScryptError {
                throw CodingError.cantCreateScryptKey(error)
            }
            throw error
        }
    }

    public static func mac(pass: String, message: Data, kdf: KdfParams) throws -> Data {
        let key = try BackupCryptoHelper.scrypt(
                pass: pass.hs.data,
                kdf: kdf)
        let startIndex = kdf.dklen / 2
        let lastHalfKey = key.suffix(from: startIndex)
        let data = lastHalfKey + message

        return Crypto.sha3(data)
    }

    public static func isValid(macHex: String, pass: String, message: Data, kdf: KdfParams) throws -> Bool {
        let sha3 = try mac(pass: pass, message: message, kdf: kdf)
        return macHex == sha3.hs.hex
    }

}

extension BackupCryptoHelper {

    enum Operation {
        case encrypt
        case decrypt

        var ccValue: CCOperation {
            switch self {
            case .encrypt: return CCOperation(kCCEncrypt)
            case .decrypt: return CCOperation(kCCDecrypt)
            }
        }
    }

    enum CodingError: Error {
        case cantCreateScryptKey(Error)
        case ivSizeError
        case ivDataError
        case cryptError
    }

}
