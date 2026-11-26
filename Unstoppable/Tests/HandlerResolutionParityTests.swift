import Testing
@testable import WalletCore

@Suite(.serialized)
struct HandlerResolutionParityTests {
    private static let builtInSendHandlers = [
        "PrivateSendHandlerProvider",
        "CrossPayHandlerProvider",
        "EvmSendHandler",
        "EvmResendHandler",
        "BitcoinResendHandler",
        "BitcoinSendHandler",
        "ZcashSendHandler",
        "ShieldSendHandler",
        "MigrationSendHandler",
        "TronSendHandler",
        "ThorChainSendHandler",
        "TonSendHandler",
        "StellarSendHandler",
        "SolanaSendHandler",
        "XrpSendHandler",
        "NearSendHandler",
        "MoneroSendHandler",
        "ZanoSendHandler",
        "MultiSwapSendHandler",
        "SplitSwapSendHandler",
        "TonConnectSendHandler",
    ]

    private static let builtInPreSendHandlers = [
        "EvmPreSendHandler",
        "BitcoinPreSendHandler",
        "ZcashPreSendHandler",
        "TronPreSendHandler",
        "ThorChainPreSendHandler",
        "TonPreSendHandler",
        "SolanaPreSendHandler",
        "StellarPreSendHandler",
        "XrpPreSendHandler",
        "NearPreSendHandler",
        "MoneroPreSendHandler",
        "ZanoPreSendHandler",
    ]

    private static let builtInTransactionServices = [
        "EvmTransactionService",
        "BitcoinResendTransactionService",
        "UtxoTransactionService",
        "MoneroTransactionService",
        "ZcashTransactionService",
    ]

    @Test func sendHandlerOrder() {
        #expect(names(HandlerRegistrations.builtIn().sendHandlers) == Self.builtInSendHandlers)
    }

    @Test func preSendHandlerOrder() {
        #expect(names(HandlerRegistrations.builtIn().preSendHandlers) == Self.builtInPreSendHandlers)
    }

    @Test func transactionServiceOrder() {
        #expect(names(HandlerRegistrations.builtIn().transactionServices) == Self.builtInTransactionServices)
    }

    @Test func swapBroadcasterOrder() {
        #expect(names(HandlerRegistrations.builtIn().swapBroadcasters) == [
            "EvmSwapBroadcaster",
            "UtxoSwapBroadcaster",
            "ZcashSwapBroadcaster",
            "TronSwapBroadcaster",
            "TonSwapBroadcaster",
            "StellarSwapBroadcaster",
            "SolanaSwapBroadcaster",
            "XrpSwapBroadcaster",
            "NearSwapBroadcaster",
            "MoneroSwapBroadcaster",
            "ZanoSwapBroadcaster",
            "ThorChainSwapBroadcaster",
        ])
    }

    @Test func nodeNetworkHandlerOrder() {
        #expect(names(HandlerRegistrations.builtIn().nodeNetworkHandlers) == [
            "ZcashNodeNetworkHandler",
            "XrpNodeNetworkHandler",
            "NearNodeNetworkHandler",
        ])
    }

    @Test func restoreSettingsHandlerOrder() {
        #expect(names(HandlerRegistrations.builtIn().restoreSettingsHandlers) == [
            "BirthdayHeightRestoreSettingsHandler",
            "NearAccountRestoreSettingsHandler",
        ])
    }

    @Test func spendStepHandlerOrder() {
        #expect(names(HandlerRegistrations.builtIn().spendStepHandlers) == [
            "ZcashShieldStepHandler",
        ])
    }

    @Test func prependedSendProvidersStayInFront() {
        let original = SendHandlerFactory.snapshot()
        defer { SendHandlerFactory.restore(handlers: original.handlers, preSendHandlers: original.preSendHandlers) }

        SendHandlerFactory.restore(handlers: [], preSendHandlers: [])
        let registrations = HandlerRegistrations.builtIn()
        registrations.sendHandlers.forEach { SendHandlerFactory.register($0) }
        registrations.preSendHandlers.forEach { SendHandlerFactory.register($0) }
        SendHandlerFactory.prepend(PrependedSendHandler.self)
        SendHandlerFactory.prepend(PrependedPreSendHandler.self)

        let snapshot = SendHandlerFactory.snapshot()

        #expect(snapshot.handlers.first.map { ObjectIdentifier($0) } == ObjectIdentifier(PrependedSendHandler.self))
        #expect(names(Array(snapshot.handlers.dropFirst())) == Self.builtInSendHandlers)
        #expect(snapshot.preSendHandlers.first.map { ObjectIdentifier($0) } == ObjectIdentifier(PrependedPreSendHandler.self))
        #expect(names(Array(snapshot.preSendHandlers.dropFirst())) == Self.builtInPreSendHandlers)
    }

    @Test func prependedTransactionServiceStaysInFront() {
        let original = TransactionServiceFactory.snapshot()
        defer { TransactionServiceFactory.restore(original) }

        TransactionServiceFactory.restore([])
        HandlerRegistrations.builtIn().transactionServices.forEach { TransactionServiceFactory.register($0) }
        TransactionServiceFactory.prepend(PrependedTransactionService.self)

        let snapshot = TransactionServiceFactory.snapshot()

        #expect(snapshot.first.map { ObjectIdentifier($0) } == ObjectIdentifier(PrependedTransactionService.self))
        #expect(names(Array(snapshot.dropFirst())) == Self.builtInTransactionServices)
    }

    private func names(_ types: [Any]) -> [String] {
        types.map { String(describing: $0) }
    }
}

private final class PrependedSendHandler: SendHandler {}

private final class PrependedPreSendHandler: PreSendHandler {}

private final class PrependedTransactionService: TransactionService {}
