public struct AppEventHandlerKind: Hashable {
    public let id: String

    public init(id: String) {
        self.id = id
    }
}

public extension AppEventHandlerKind {
    static let walletConnect = AppEventHandlerKind(id: "wallet_connect")
    static let widgetCoin = AppEventHandlerKind(id: "widget_coin")
    static let address = AppEventHandlerKind(id: "address")
    static let telegramUser = AppEventHandlerKind(id: "telegram_user")
    static let openCryptoPay = AppEventHandlerKind(id: "open_crypto_pay")
}
