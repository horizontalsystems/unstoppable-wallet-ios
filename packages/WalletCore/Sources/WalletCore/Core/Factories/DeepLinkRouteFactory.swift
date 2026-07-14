public enum DeepLinkRouteFactory {
    // Empty by default: every app registers its own set before Core.initApp.
    // Registration after Core.initApp has no effect.
    private static var routes = Set<DeepLinkRoute>()
    private static var appTransferScheme: String?

    public static func register(_ route: DeepLinkRoute) {
        routes.insert(route)
    }

    // App-scheme transfer links (<scheme>://send?uri=...): the app provides its own url scheme,
    // which must also be declared in its Info.plist CFBundleURLTypes.
    public static func register(appTransferScheme: String) {
        routes.insert(.appTransfer)
        self.appTransferScheme = appTransferScheme
    }

    static func resolved() -> Set<DeepLinkRoute> {
        routes
    }

    // Built-in matchers in fixed priority order — it does not depend on route registration order;
    // the generic transfer matcher is the catch-all and always goes last.
    static func matchers() -> [IDeepLinkMatcher] {
        var builtIn: [IDeepLinkMatcher] = [
            WalletConnectDeepLinkMatcher(),
            TonConnectDeepLinkMatcher(),
            TonTransferDeepLinkMatcher(),
            CoinDeepLinkMatcher(),
            ReferralDeepLinkMatcher(),
            OpenCryptoPayDeepLinkMatcher(),
        ]

        if let appTransferScheme {
            builtIn.append(AppSchemeTransferDeepLinkMatcher(scheme: appTransferScheme))
        }

        builtIn.append(TransferDeepLinkMatcher())

        return builtIn.filter { routes.contains($0.route) }
    }

    // Routes and handler kinds are registered independently, but a route without its consuming
    // handler is a silent no-op (EventHandler reports .handled without any UI). Catch the mismatch in debug.
    // DeepLinkRoute.tonConnect is intentionally dangling: TonConnectEventHandler is disabled in Core.
    static func assertCoherence(handlerKinds: Set<AppEventHandlerKind>) {
        let consumers: [DeepLinkRoute: AppEventHandlerKind] = [
            .walletConnect: .walletConnect,
            .tonTransfer: .address,
            .coin: .widgetCoin,
            .referral: .telegramUser,
            .openCryptoPay: .openCryptoPay,
            .transfer: .address,
            .appTransfer: .address,
        ]

        for route in routes {
            guard let kind = consumers[route], !handlerKinds.contains(kind) else {
                continue
            }

            assertionFailure("DeepLink route '\(route.id)' is registered but its consuming handler '\(kind.id)' is not")
        }
    }
}
