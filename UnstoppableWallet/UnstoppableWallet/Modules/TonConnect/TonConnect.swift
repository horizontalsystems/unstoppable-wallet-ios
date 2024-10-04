import Foundation
import TonSwift

enum TonConnect {
    enum Network: Int16, Hashable {
        case mainnet = -239
        case testnet = -3
    }

    enum ConnectEvent: Encodable {
        case success(ConnectEventSuccess)
        case error(ConnectEventError)
    }

    struct DeviceInfo: Encodable {
        let platform = "iphone"
        let appName = "Tonkeeper"
        let appVersion = "3.4.0"
        // let appName = AppConfig.appName
        // let appVersion = AppConfig.appVersion
        let maxProtocolVersion = 2
        let features = [
            FeatureCompatible.legacy(Feature()),
            FeatureCompatible.feature(Feature()),
        ]

        enum FeatureCompatible: Encodable {
            case feature(Feature)
            case legacy(Feature)

            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case let .feature(feature):
                    try container.encode(feature)
                case let .legacy(feature):
                    try container.encode(feature.name)
                }
            }
        }

        struct Feature: Encodable {
            let name = "SendTransaction"
            let maxMessages = 4
        }

        init() {}
    }

    struct ConnectEventSuccess: Encodable {
        struct Payload: Encodable {
            let items: [ConnectItemReply]
            let device: DeviceInfo
        }

        let event = "connect"
        let id = Int(Date().timeIntervalSince1970)
        let payload: Payload
    }

    struct ConnectEventError: Encodable {
        struct Payload: Encodable {
            let code: Error
            let message: String
        }

        enum Error: Int, Encodable, Swift.Error {
            case unknownError = 0
            case badRequest = 1
            case appManifestNotFound = 2
            case appManifestContentError = 3
            case unknownApp = 100
            case userDeclinedTheConnection = 300
        }

        let event = "connect_error"
        let id = Int(Date().timeIntervalSince1970)
        let payload: Payload
    }

    struct DisconnectEvent: Encodable {
        let event = "disconnect"
        let id = Int(Date().timeIntervalSince1970)
    }

    enum ConnectItemReply: Encodable {
        case tonAddress(TonAddressItemReply)
        case tonProof(TonProofItemReply)
    }

    struct TonAddressItemReply: Encodable {
        let name = "ton_addr"
        let address: TonSwift.Address
        let network: Network
        let publicKey: TonSwift.PublicKey
        let walletStateInit: TonSwift.StateInit
    }

    enum TonProofItemReply: Encodable {
        case success(TonProofItemReplySuccess)
        case error(TonProofItemReplyError)
    }

    struct TonProofItemReplySuccess: Encodable {
        struct Proof: Encodable {
            let timestamp: UInt64
            let domain: Domain
            let signature: Signature
            let payload: String
            let privateKey: PrivateKey
        }

        struct Signature: Encodable {
            let address: TonSwift.Address
            let domain: Domain
            let timestamp: UInt64
            let payload: String
        }

        struct Domain: Encodable {
            let lengthBytes: UInt32
            let value: String
        }

        let name = "ton_proof"
        let proof: Proof
    }

    struct TonProofItemReplyError: Encodable {
        struct Error: Encodable {
            let message: String?
            let code: ErrorCode
        }

        enum ErrorCode: Int, Encodable {
            case unknownError = 0
            case methodNotSupported = 400
        }

        let name = "ton_proof"
        let error: Error
    }
}

extension TonConnect.TonProofItemReplySuccess {
    init(address: TonSwift.Address,
         domain: String,
         payload: String,
         privateKey: PrivateKey)
    {
        let timestamp = UInt64(Date().timeIntervalSince1970)
        let domain = Domain(domain: domain)
        let signature = Signature(
            address: address,
            domain: domain,
            timestamp: timestamp,
            payload: payload
        )
        let proof = Proof(
            timestamp: timestamp,
            domain: domain,
            signature: signature,
            payload: payload,
            privateKey: privateKey
        )

        self.init(proof: proof)
    }
}

extension TonConnect.TonProofItemReplySuccess.Domain {
    init(domain: String) {
        let domainLength = UInt32(domain.utf8.count)
        value = domain
        lengthBytes = domainLength
    }
}

extension TonConnect {
    enum SendTransactionResponse {
        case success(SendTransactionResponseSuccess)
        case error(SendTransactionResponseError)
    }

    struct SendTransactionResponseSuccess: Encodable {
        let result: String
        let id: String

        init(result: String, id: String) {
            self.result = result
            self.id = id
        }
    }

    struct SendTransactionResponseError: Encodable {
        struct Error: Encodable {
            let code: ErrorCode
            let message: String

            init(code: ErrorCode, message: String) {
                self.code = code
                self.message = message
            }
        }

        enum ErrorCode: Int, Encodable, Swift.Error {
            case unknownError = 0
            case badRequest = 1
            case unknownApp = 10
            case userDeclinedTransaction = 300
            case methodNotSupported = 400
        }

        let id: String
        let error: Error

        init(id: String, error: Error) {
            self.id = id
            self.error = error
        }
    }
}

extension TonConnect {
    struct AppRequest: Decodable {
        enum Method: String, Decodable {
            case sendTransaction
            case disconnect
        }

        let method: Method
        let params: [SendTransactionParam]
        let id: String

        enum CodingKeys: String, CodingKey {
            case method
            case params
            case id
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            method = try container.decode(Method.self, forKey: .method)
            id = try container.decode(String.self, forKey: .id)
            let paramsArray = try container.decode([String].self, forKey: .params)
            let jsonDecoder = JSONDecoder()
            params = paramsArray.compactMap {
                guard let data = $0.data(using: .utf8) else { return nil }
                return try? jsonDecoder.decode(SendTransactionParam.self, from: data)
            }
        }
    }
}

extension TonConnect.Network: CellCodable {
    func storeTo(builder: Builder) throws {
        try builder.store(int: rawValue, bits: .rawValueLength)
    }

    static func loadFrom(slice: Slice) throws -> TonConnect.Network {
        try slice.tryLoad { s in
            let rawValue = try Int16(s.loadInt(bits: .rawValueLength))
            guard let network = TonConnect.Network(rawValue: rawValue) else {
                throw TonSwift.TonError.custom("Invalid network code")
            }
            return network
        }
    }
}

private extension Int {
    static let rawValueLength = 16
}

public struct SendTransactionParam: Decodable {
    let messages: [Message]
    let validUntil: TimeInterval
    let from: TonSwift.Address?

    enum CodingKeys: String, CodingKey {
        case messages
        case validUntil = "valid_until"
        case from
        case source
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        messages = try container.decode([Message].self, forKey: .messages)
        validUntil = try container.decode(TimeInterval.self, forKey: .validUntil)

        if let fromValue = try? container.decode(String.self, forKey: .from) {
            from = try TonSwift.Address.parse(fromValue)
        } else {
            from = try TonSwift.Address.parse(container.decode(String.self, forKey: .source))
        }
    }

    public struct Message: Decodable {
        let address: TonSwift.Address
        let amount: Int64
        let stateInit: String?
        let payload: String?

        enum CodingKeys: String, CodingKey {
            case address
            case amount
            case stateInit
            case payload
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            address = try TonSwift.Address.parse(container.decode(String.self, forKey: .address))
            amount = try Int64(container.decode(String.self, forKey: .amount)) ?? 0
            stateInit = try container.decodeIfPresent(String.self, forKey: .stateInit)
            payload = try container.decodeIfPresent(String.self, forKey: .payload)
        }
    }
}

public struct SendTransactionSignRequest: Decodable {
    public let params: [SendTransactionParam]

    enum CodingKeys: String, CodingKey {
        case params
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var params = [SendTransactionParam]()
        while !container.isAtEnd {
            let param = try container.decode(SendTransactionParam.self)
            params.append(param)
        }
        self.params = params
    }
}
