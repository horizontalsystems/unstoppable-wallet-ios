import Foundation
import TonSwift
import TweetNacl

extension TonConnect.ConnectEvent {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .success(success):
            try container.encode(success)
        case let .error(error):
            try container.encode(error)
        }
    }
}

extension TonConnect.ConnectItemReply {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .tonAddress(address):
            try container.encode(address)
        case let .tonProof(proof):
            try container.encode(proof)
        }
    }
}

extension TonConnect.TonProofItemReply {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .success(success):
            try container.encode(success)
        case let .error(error):
            try container.encode(error)
        }
    }
}

extension TonConnect.TonAddressItemReply {
    enum CodingKeys: String, CodingKey {
        case name
        case address
        case network
        case publicKey
        case walletStateInit
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(address.toRaw(), forKey: .address)
        try container.encode("\(network.rawValue)", forKey: .network)
        try container.encode(publicKey.hexString, forKey: .publicKey)

        let builder = Builder()
        try walletStateInit.storeTo(builder: builder)
        try container.encode(
            builder.endCell().toBoc().base64EncodedString(),
            forKey: .walletStateInit
        )
    }
}

extension TonConnect.TonProofItemReplySuccess.Signature {
    func data() -> Data {
        let string = "ton-proof-item-v2/".data(using: .utf8)!
        let addressWorkchain = UInt32(bigEndian: UInt32(address.workchain))

        let addressWorkchainData = withUnsafeBytes(of: addressWorkchain) { a in
            Data(a)
        }
        let addressHash = address.hash
        let domainLength = withUnsafeBytes(of: UInt32(littleEndian: domain.lengthBytes)) { a in
            Data(a)
        }
        let domainValue = domain.value.data(using: .utf8)!
        let timestamp = withUnsafeBytes(of: UInt64(littleEndian: timestamp)) { a in
            Data(a)
        }
        let payload = payload.data(using: .utf8)!

        return string + addressWorkchainData + addressHash + domainLength + domainValue + timestamp + payload
    }
}

extension TonConnect.TonProofItemReplySuccess.Proof {
    enum CodingKeys: String, CodingKey {
        case timestamp
        case domain
        case signature
        case payload
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(domain, forKey: .domain)

        let signatureMessageData = signature.data()
        let signatureMessage = signatureMessageData.sha256()
        guard let prefixData = Data(hex: "ffff"),
              let tonConnectData = "ton-connect".data(using: .utf8)
        else {
            return
        }
        let signatureData = (prefixData + tonConnectData + signatureMessage).sha256()
        let signature = try TweetNacl.NaclSign.signDetached(
            message: signatureData,
            secretKey: privateKey.data
        )
        try container.encode(signature, forKey: .signature)
        try container.encode(payload, forKey: .payload)
    }
}

extension TonConnect.SendTransactionResponse: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .success(success):
            try container.encode(success)
        case let .error(error):
            try container.encode(error)
        }
    }
}
