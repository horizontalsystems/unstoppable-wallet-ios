import EvmKit
import Foundation
import Testing
@testable import WalletCore

struct EvmResendFeeTests {
    private func transaction(gasPrice: Int? = nil, maxFee: Int? = nil, tips: Int? = nil) -> EvmKit.Transaction {
        EvmKit.Transaction(hash: Data(), timestamp: 0, isFailed: false, nonce: 7, gasPrice: gasPrice, maxFeePerGas: maxFee, maxPriorityFeePerGas: tips)
    }

    @Test func legacyPreservesExistingRecommendationAndDefaultSelection() {
        let prices = EvmTransactionService.gasPriceData(network: .legacy(gasPrice: 100), previousTransaction: transaction(gasPrice: 150), custom: nil)

        #expect(prices.recommended == .legacy(gasPrice: 150))
        #expect(prices.userDefined == .legacy(gasPrice: 100))
    }

    @Test func legacyManualSelectionEqualToRecommendationIsStillPreserved() {
        let original = transaction(gasPrice: 150)
        let prices = EvmTransactionService.gasPriceData(network: .legacy(gasPrice: 100), previousTransaction: original, custom: .legacy(gasPrice: 150))
        let reset = EvmTransactionService.gasPriceData(network: .legacy(gasPrice: 100), previousTransaction: original, custom: nil)

        #expect(prices.userDefined == .legacy(gasPrice: 150))
        #expect(reset.userDefined == .legacy(gasPrice: 100))
    }

    @Test func eip1559PreservesPreviousTipsAndMaxFeeWithoutNewBump() {
        let prices = EvmTransactionService.gasPriceData(network: .eip1559(maxFeePerGas: 100, maxPriorityFeePerGas: 2), previousTransaction: transaction(maxFee: 120, tips: 5), custom: nil)

        #expect(prices.recommended == .eip1559(maxFeePerGas: 120, maxPriorityFeePerGas: 5))
        #expect(prices.userDefined == prices.recommended)
    }

    @Test func eip1559KeepsNetworkBaseFeeWhenPreviousTipsAreHigher() {
        let prices = EvmTransactionService.gasPriceData(network: .eip1559(maxFeePerGas: 100, maxPriorityFeePerGas: 2), previousTransaction: transaction(maxFee: 90, tips: 10), custom: nil)

        #expect(prices.recommended == .eip1559(maxFeePerGas: 108, maxPriorityFeePerGas: 10))
    }

    @Test(arguments: [GasPrice.legacy(gasPrice: 170), .eip1559(maxFeePerGas: 170, maxPriorityFeePerGas: 8)])
    func refreshKeepsManualFee(custom: GasPrice) {
        let original = transaction(gasPrice: 150, maxFee: 150, tips: 5)
        let first = EvmTransactionService.gasPriceData(network: custom, previousTransaction: original, custom: custom)
        let refreshedNetwork: GasPrice
        switch custom {
        case .legacy: refreshedNetwork = .legacy(gasPrice: 200)
        case .eip1559: refreshedNetwork = .eip1559(maxFeePerGas: 200, maxPriorityFeePerGas: 10)
        }
        let refreshed = EvmTransactionService.gasPriceData(network: refreshedNetwork, previousTransaction: original, custom: custom)

        #expect(first.userDefined == custom)
        #expect(refreshed.userDefined == custom)
        #expect(refreshed.recommended == refreshedNetwork)
    }

    @Test(arguments: [GasPrice.legacy(gasPrice: 100), .eip1559(maxFeePerGas: 100, maxPriorityFeePerGas: 2)])
    func ordinarySendStillUsesNetworkRecommendation(network: GasPrice) {
        let prices = EvmTransactionService.gasPriceData(network: network, previousTransaction: nil, custom: nil)

        #expect(prices.recommended == network)
        #expect(prices.userDefined == network)
    }
}
