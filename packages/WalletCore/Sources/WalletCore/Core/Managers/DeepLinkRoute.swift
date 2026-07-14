public struct DeepLinkRoute: Hashable {
    public let id: String

    public init(id: String) {
        self.id = id
    }
}

public extension DeepLinkRoute {
    static let walletConnect = DeepLinkRoute(id: "wallet_connect")
    static let tonConnect = DeepLinkRoute(id: "ton_connect")
    static let tonTransfer = DeepLinkRoute(id: "ton_transfer")
    static let coin = DeepLinkRoute(id: "coin")
    static let referral = DeepLinkRoute(id: "referral")
    static let openCryptoPay = DeepLinkRoute(id: "open_crypto_pay")
    static let transfer = DeepLinkRoute(id: "transfer")
}
