import Foundation
import WalletKit.Private

public struct Crypto {

    public static func sha256(_ data: Data) -> Data {
        return _Hash.sha256(data)
    }
    
    public static func sha256sha256(_ data: Data) -> Data {
        return sha256(sha256(data))
    }

    public static func ripemd160(_ data: Data) -> Data {
        return _Hash.ripemd160(data)
    }

    public static func sha256ripemd160(_ data: Data) -> Data {
        return ripemd160(sha256(data))
    }

    public static func hmacsha512(data: Data, key: Data) -> Data {
        return _Hash.hmacsha512(data, key: key)
    }

}
