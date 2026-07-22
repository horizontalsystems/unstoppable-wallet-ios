import Testing
import ThorChainKit
@testable import WalletCore

struct ThorChainKitManagerTests {
    @Test func unsupportedAccountFailsBeforeFactoryAccess() {
        let factory = RecordingThorChainKitFactory()
        let manager = ThorChainKitManager(
            endpointProvider: FailingThorChainEndpointProvider(),
            kitFactory: factory
        )
        let account = Account(
            id: "unsupported",
            level: 0,
            name: "Unsupported",
            type: .tonAddress(address: "unsupported"),
            origin: .created,
            backedUp: false,
            fileBackedUp: false
        )

        do {
            _ = try manager.thorChainKitWrapper(account: account)
            Issue.record("unsupported account was accepted")
        } catch {
            #expect((error as? ThorChainKitManagerError) == .unsupportedAccount)
        }
        #expect(factory.callCount == 0)
    }
}

private struct FailingThorChainEndpointProvider: IThorChainEndpointConfigurationProvider {
    func configuration() throws -> ThorChainEndpointConfiguration {
        fatalError("provider must not be consulted")
    }
}

private final class RecordingThorChainKitFactory: IThorChainKitFactory {
    var callCount = 0

    func kit(
        address: ThorChainKit.Address,
        walletId: String,
        endpoints: ThorChainKit.EndpointConfiguration
    ) throws -> any IThorChainKit {
        callCount += 1
        fatalError("factory must not be consulted")
    }
}
