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
    // handler is a dead parse (the link only dies in the handler chain). Catch the mismatch in debug.
    // DeepLinkRoute.tonConnect has no entry: TonConnectEventHandler is disabled in Core, so the route
    // must not be registered until the handler is re-enabled (and mapped here).
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
