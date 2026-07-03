import Foundation
import MarketKit
import Testing
@testable import Unstoppable
@testable import WalletCore

@Suite(.serialized)
struct SwapBroadcasterFactoryTests {
    private static let account = Account(
        id: "test", level: 0, name: "Test",
        type: .mnemonic(words: [], salt: "", bip39Compliant: true),
        origin: .created, backedUp: true, fileBackedUp: false
    )

    init() {
        SwapBroadcasterFactory.reset()
    }

    @Test func resolvesRegisteredType() throws {
        SwapBroadcasterFactory.register([MatchingType.self])

        let broadcaster = try SwapBroadcasterFactory.broadcaster(blockchainType: .ethereum, account: Self.account)

        let stub = try #require(broadcaster as? StubBroadcaster)
        #expect(stub.id == "matching")
    }

    @Test func prependWinsOverRegistered() throws {
        SwapBroadcasterFactory.register([MatchingType.self])
        SwapBroadcasterFactory.prepend(PrependedType.self)

        let broadcaster = try SwapBroadcasterFactory.broadcaster(blockchainType: .ethereum, account: Self.account)

        let stub = try #require(broadcaster as? StubBroadcaster)
        #expect(stub.id == "prepended")
    }

    @Test func emptyRegistryThrowsNoBroadcaster() {
        #expect(throws: SwapBroadcasterError.noBroadcaster) {
            _ = try SwapBroadcasterFactory.broadcaster(blockchainType: .ethereum, account: Self.account)
        }
    }

    // fail-closed: a type that declines must never fall through to raw sending
    @Test func nothingResolvesThrowsNoBroadcaster() {
        SwapBroadcasterFactory.register([DecliningType.self])

        #expect(throws: SwapBroadcasterError.noBroadcaster) {
            _ = try SwapBroadcasterFactory.broadcaster(blockchainType: .ethereum, account: Self.account)
        }
    }

    @Test func decliningTypeIsSkipped() throws {
        SwapBroadcasterFactory.register([DecliningType.self, MatchingType.self])

        let broadcaster = try SwapBroadcasterFactory.broadcaster(blockchainType: .ethereum, account: Self.account)

        let stub = try #require(broadcaster as? StubBroadcaster)
        #expect(stub.id == "matching")
    }

    // downstream apps extend SwapBroadcasterError without touching WalletCore
    @Test func errorIsExtensible() {
        #expect(SwapBroadcasterError.stubExternal == SwapBroadcasterError(rawValue: "stubExternal"))
        #expect(SwapBroadcasterError.stubExternal != .noBroadcaster)
    }
}

private extension SwapBroadcasterError {
    static var stubExternal: Self { .init(rawValue: "stubExternal") }
}

private struct StubBroadcaster: ISwapBroadcaster {
    let id: String

    func prepare(_ executable: ISwapExecutable) async throws -> IPrepared {
        EoaPrepared(executable: executable)
    }

    func submit(_: IPrepared) async throws -> BroadcastResult {
        BroadcastResult(onChainTxHash: nil, trackingHandle: nil)
    }
}

private enum MatchingType: ISwapBroadcasterType {
    static func make(blockchainType _: BlockchainType, account _: Account) -> ISwapBroadcaster? {
        StubBroadcaster(id: "matching")
    }
}

private enum PrependedType: ISwapBroadcasterType {
    static func make(blockchainType _: BlockchainType, account _: Account) -> ISwapBroadcaster? {
        StubBroadcaster(id: "prepended")
    }
}

private enum DecliningType: ISwapBroadcasterType {
    static func make(blockchainType _: BlockchainType, account _: Account) -> ISwapBroadcaster? {
        nil
    }
}
