import Foundation
import MarketKit
import Testing
import UniswapKit
@testable import WalletCore

struct LegacyModuleContractTests {
    @Test(arguments: [
        ("Uniswap", "uniswap"), ("Uniswap V3", "uniswap_v3"), ("1Inch", "oneinch"),
        ("PancakeSwap", "pancake"), ("PancakeSwap V3", "pancake_v3"), ("QuickSwap", "quickswap"),
    ])
    func legacyProviderPreservesStoredValueAndBackupId(raw: String, id: String) throws {
        let provider = try #require(LegacySwapProvider(rawValue: raw))
        #expect(provider.rawValue == raw)
        #expect(provider.id == id)
        let backup = SettingsBackup.DefaultProvider(blockchainTypeId: "ethereum", provider: provider.id)
        let data = try JSONEncoder().encode(backup)
        let restored = try JSONDecoder().decode(SettingsBackup.DefaultProvider.self, from: data)
        #expect(restored.blockchainTypeId == "ethereum")
        #expect(restored.provider == id)
    }

    @Test func legacyProviderDefaultsKeepTheirOrder() {
        #expect(BlockchainType.ethereum.legacySwapProviders.map(\.rawValue) == ["1Inch", "Uniswap", "Uniswap V3", "PancakeSwap V3"])
        #expect(BlockchainType.binanceSmartChain.legacySwapProviders.map(\.rawValue) == ["1Inch", "PancakeSwap", "PancakeSwap V3", "Uniswap V3"])
        #expect(BlockchainType.polygon.legacySwapProviders.map(\.rawValue) == ["1Inch", "QuickSwap", "Uniswap V3"])
        #expect(BlockchainType.zkSync.legacySwapProviders.map(\.rawValue) == ["Uniswap V3", "PancakeSwap V3"])
        #expect(BlockchainType.bitcoin.legacySwapProviders.isEmpty)
        #expect(LegacySwapProvider(rawValue: "unknown") == nil)
    }

    @Test(arguments: [
        (Decimal.zero, "swap.advanced_settings.error.invalid_slippage", CautionType.error),
        (Decimal(9) / 1000, "swap.advanced_settings.error.lower_slippage", .error),
        (Decimal(5), "swap.advanced_settings.warning.unusual_slippage", .warning),
        (Decimal(50), "swap.advanced_settings.warning.unusual_slippage", .warning),
    ])
    func slippageKeepsMessagesAndSeverity(value: Decimal, key: String, type: CautionType) throws {
        let caution = try #require(MultiSwapSlippage.validate(slippage: value).caution)
        #expect(caution.text == key.localized)
        #expect(caution.type == type)
    }

    @Test func slippageBoundsRemainInclusive() throws {
        #expect(MultiSwapSlippage.validate(slippage: Decimal(1) / 100) == .none)
        let caution = try #require(MultiSwapSlippage.validate(slippage: Decimal(5001) / 100).caution)
        #expect(caution.type == .error)
        #expect(caution.text == "swap.advanced_settings.error.higher_slippage".localized("50"))
    }

    @Test func relocatedErrorConformancesRemainVisibleThroughError() {
        let address: Error = AddressService.AddressError.invalidAddress(blockchainName: "Ethereum")
        #expect(address.localizedDescription == ["send.error.invalid".localized, "Ethereum", "send.error.address".localized].joined(separator: " "))
        let wrongBlockchain: Error = AddressUriParser.ParseError.invalidBlockchainType
        let wrongToken: Error = AddressUriParser.ParseError.invalidTokenType
        let invalidUri: Error = AddressUriParser.ParseError.wrongUri
        #expect(wrongBlockchain.localizedDescription == "send.error.invalid_blockchain".localized)
        #expect(wrongToken.localizedDescription == "send.error.invalid_token".localized)
        #expect(invalidUri.localizedDescription == "alert.cant_recognize".localized)
        let v2: Error = UniswapKit.Kit.TradeError.tradeNotFound
        let v3: Error = UniswapKit.KitV3.TradeError.tradeNotFound
        #expect(v2.localizedDescription == "swap.trade_error.not_found".localized)
        #expect(v3.localizedDescription == "swap.trade_error.not_found".localized)
    }

    @Test func feeFactoryPreservesDecimalPrecisionAndNonnegativeSteps() {
        let factory = FeeViewItemFactory(scale: .gwei)
        let value = Decimal(1_234_567_891) / 1_000_000_000
        #expect(factory.decimalValue(value: 1_234_567_891) == value)
        #expect(factory.intValue(value: value) == 1_234_567_891)
        #expect(factory.updated(value: 1, percent: 10, direction: .down) == Decimal(9) / 10)
        #expect(factory.updated(value: 1, percent: 10, direction: .up) == Decimal(11) / 10)
        #expect(factory.updated(value: 1, percent: 200, direction: .down) == .zero)
    }
}
