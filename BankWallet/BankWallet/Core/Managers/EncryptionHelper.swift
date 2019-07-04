import Foundation
import CommonCrypto

class UUIDProvider: IUUIDProvider {

    func generate() -> String {
        return UUID().uuidString
    }

}

class EncryptionHelper: IEncryptionManager {
    static let shared = EncryptionHelper(secureStorage: KeychainStorage(localStorage: UserDefaultsStorage.shared), passwordProvider: UUIDProvider())

    let secureStorage: ISecureStorage
    let passwordProvider: IUUIDProvider

    init(secureStorage: ISecureStorage, passwordProvider: IUUIDProvider) {
        self.secureStorage = secureStorage
        self.passwordProvider = passwordProvider
    }

    private func getPassword() throws -> String {
        if let password = secureStorage.encryptionPassword {
            print("pass from secure storage: \(password)")
            return password
        } else {
            let password = passwordProvider.generate()
            try secureStorage.set(encryptionPassword: password)
            print("pass generated: \(password)")
            return password
        }
    }

    private func getSalt() throws -> Data {
        if let salt: Data = secureStorage.encryptionSalt {
            print("salt from secure storage: \(salt.toHexString())")
            return salt
        } else {
            let salt = AES256Crypter.randomSalt()
            print("salt generated: \(salt.toHexString())")
            try secureStorage.set(encryptionSalt: salt)
            return salt
        }
    }

    private func getIv() throws -> Data {
        if let iv: Data = secureStorage.encryptionIv {
            print("iv from secure storage: \(iv.toHexString())")
            return iv
        } else {
            let iv = AES256Crypter.randomIv()
            print("iv generated: \(iv.toHexString())")
            try secureStorage.set(encryptionIv: iv)
            return iv
        }
    }

    func encrypt(data: Data) throws -> Data {
        let password = try getPassword()
        let salt = try getSalt()
        let iv = try getIv()
        let key = try AES256Crypter.createKey(password: password.data(using: .utf8)!, salt: salt)
        let aes = try AES256Crypter(key: key, iv: iv)
        return try aes.encrypt(data)
    }

    func decrypt(data: Data) throws -> Data {
        let password = try getPassword()
        let salt = try getSalt()
        let iv = try getIv()
        let key = try AES256Crypter.createKey(password: password.data(using: .utf8)!, salt: salt)
        let aes = try AES256Crypter(key: key, iv: iv)
        return try aes.decrypt(data)
    }

}


protocol Randomizer {
    static func randomIv() -> Data
    static func randomSalt() -> Data
    static func randomData(length: Int) -> Data
}

protocol Crypter {
    func encrypt(_ digest: Data) throws -> Data
    func decrypt(_ encrypted: Data) throws -> Data
}

struct AES256Crypter {

    private var key: Data
    private var iv: Data

    public init(key: Data, iv: Data) throws {
        guard key.count == kCCKeySizeAES256 else {
            throw Error.badKeyLength
        }
        guard iv.count == kCCBlockSizeAES128 else {
            throw Error.badInputVectorLength
        }
        self.key = key
        self.iv = iv
    }

    enum Error: Swift.Error {
        case keyGeneration(status: Int)
        case cryptoFailed(status: CCCryptorStatus)
        case badKeyLength
        case badInputVectorLength
    }

    private func crypt(input: Data, operation: CCOperation) throws -> Data {
        var outLength = Int(0)
        var outBytes = [UInt8](repeating: 0, count: input.count + kCCBlockSizeAES128)
        var status: CCCryptorStatus = CCCryptorStatus(kCCSuccess)
        input.withUnsafeBytes { (encryptedBytes: UnsafePointer<UInt8>!) -> () in
            iv.withUnsafeBytes { (ivBytes: UnsafePointer<UInt8>!) in
                key.withUnsafeBytes { (keyBytes: UnsafePointer<UInt8>!) -> () in
                    status = CCCrypt(operation,
                            CCAlgorithm(kCCAlgorithmAES128),            // algorithm
                            CCOptions(kCCOptionPKCS7Padding),           // options
                            keyBytes,                                   // key
                            key.count,                                  // keylength
                            ivBytes,                                    // iv
                            encryptedBytes,                             // dataIn
                            input.count,                                // dataInLength
                            &outBytes,                                  // dataOut
                            outBytes.count,                             // dataOutAvailable
                            &outLength)                                 // dataOutMoved
                }
            }
        }
        guard status == kCCSuccess else {
            throw Error.cryptoFailed(status: status)
        }
        return Data(bytes: UnsafePointer<UInt8>(outBytes), count: outLength)
    }

    static func createKey(password: Data, salt: Data) throws -> Data {
        let length = kCCKeySizeAES256
        var status = Int32(0)
        var derivedBytes = [UInt8](repeating: 0, count: length)
        password.withUnsafeBytes { (passwordBytes: UnsafePointer<Int8>!) in
            salt.withUnsafeBytes { (saltBytes: UnsafePointer<UInt8>!) in
                status = CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2),                  // algorithm
                        passwordBytes,                                // password
                        password.count,                               // passwordLen
                        saltBytes,                                    // salt
                        salt.count,                                   // saltLen
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1),   // prf
                        10000,                                        // rounds
                        &derivedBytes,                                // derivedKey
                        length)                                       // derivedKeyLen
            }
        }
        guard status == 0 else {
            throw Error.keyGeneration(status: Int(status))
        }
        return Data(bytes: UnsafePointer<UInt8>(derivedBytes), count: length)
    }

}

extension AES256Crypter: Crypter {

    func encrypt(_ digest: Data) throws -> Data {
        return try crypt(input: digest, operation: CCOperation(kCCEncrypt))
    }

    func decrypt(_ encrypted: Data) throws -> Data {
        return try crypt(input: encrypted, operation: CCOperation(kCCDecrypt))
    }

}

extension AES256Crypter: Randomizer {

    static func randomIv() -> Data {
        return randomData(length: kCCBlockSizeAES128)
    }

    static func randomSalt() -> Data {
        return randomData(length: 8)
    }

    static func randomData(length: Int) -> Data {
        var data = Data(count: length)
        let status = data.withUnsafeMutableBytes { mutableBytes in
            SecRandomCopyBytes(kSecRandomDefault, length, mutableBytes)
        }
        assert(status == Int32(0))
        return data
    }

}