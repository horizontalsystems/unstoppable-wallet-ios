import MarketKit
import Testing
@testable import WalletCore

struct ThorChainSwapMemoTests {
    private let evmAddress = "0x1234567890abcdef1234567890abcdef12345678"

    @Test(arguments: ["=", "s", "SWAP"])
    func acceptsSwapAliasesAndOptionalRefund(_ operation: String) throws {
        try ThorChainSwapMemo.validate("\(operation):ETH.ETH:\(evmAddress)/refund:123", expectedDestination: evmAddress, blockchainType: .ethereum)
    }

    @Test(arguments: ["", "=:ETH.ETH", "=:ETH.ETH::123", "ADD:ETH.ETH:destination", "=:ETH.ETH:/refund"])
    func rejectsMissingOrNonSwapDestination(_ memo: String) {
        #expect(throws: ThorChainSwapMemo.ValidationError.invalidMemo) {
            try ThorChainSwapMemo.validate(memo, expectedDestination: evmAddress, blockchainType: .ethereum)
        }
    }

    @Test func rejectsUnexpectedDestination() {
        #expect(throws: ThorChainSwapMemo.ValidationError.destinationMismatch) {
            try ThorChainSwapMemo.validate("=:ETH.ETH:0x0000000000000000000000000000000000000000", expectedDestination: evmAddress, blockchainType: .ethereum)
        }
    }

    @Test func comparesHexCaseInsensitively() throws {
        try ThorChainSwapMemo.validate("=:ETH.ETH:\(evmAddress.uppercased())", expectedDestination: evmAddress, blockchainType: .ethereum)
    }

    @Test func comparesSingleCaseBech32WithoutFoldingBase58() throws {
        let bech32 = "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"
        try ThorChainSwapMemo.validate("=:BTC.BTC:\(bech32.uppercased())", expectedDestination: bech32, blockchainType: .bitcoin)
        #expect(throws: ThorChainSwapMemo.ValidationError.destinationMismatch) {
            try ThorChainSwapMemo.validate("=:BTC.BTC:bc1Qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh", expectedDestination: bech32, blockchainType: .bitcoin)
        }
        let base58 = "1BoatSLRHtKNngkdXEeobR76b53LETtpyT"
        #expect(throws: ThorChainSwapMemo.ValidationError.destinationMismatch) {
            try ThorChainSwapMemo.validate("=:BTC.BTC:\(base58.lowercased())", expectedDestination: base58, blockchainType: .bitcoin)
        }
    }

    @Test func acceptsCashAddressPrefixAndCase() throws {
        let payload = "qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx6a"
        try ThorChainSwapMemo.validate("=:BCH.BCH:\(payload.uppercased())/refund:123", expectedDestination: "bitcoincash:\(payload)", blockchainType: .bitcoinCash)
        try ThorChainSwapMemo.validate("=:BCH.BCH:bitcoincash:\(payload):123", expectedDestination: payload, blockchainType: .bitcoinCash)
        #expect(throws: ThorChainSwapMemo.ValidationError.destinationMismatch) {
            try ThorChainSwapMemo.validate("=:BCH.BCH:qPM2qsznhks23z7629mms6s4cwef74vcwvy22gdx6a", expectedDestination: payload, blockchainType: .bitcoinCash)
        }
    }
}
