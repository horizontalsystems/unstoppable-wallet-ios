import EvmKit
import Foundation
import Testing
@testable import WalletCore

struct EvmTransactionValidationTests {
    @Test(arguments: [
        (89, [EvmTransactionService.GasDataWarning.riskOfGettingStuck]),
        (90, []), (100, []), (150, []),
        (151, [.overpricing]),
    ])
    func legacyWarningsRespectInclusiveBounds(price: Int, expected: [EvmTransactionService.GasDataWarning]) {
        let warnings = EvmTransactionService.validateGasPrice(recommended: .legacy(gasPrice: 100), current: .legacy(gasPrice: price))
        #expect(warnings.map(\.titledCaution) == expected.map(\.titledCaution))
    }

    @Test(arguments: [
        (89, [EvmTransactionService.GasDataWarning.riskOfGettingStuck]),
        (90, []), (100, []), (150, []),
        (151, [.overpricing]),
    ])
    func eip1559WarningsRespectInclusiveBounds(tips: Int, expected: [EvmTransactionService.GasDataWarning]) {
        let recommended = GasPrice.eip1559(maxFeePerGas: 100 + GasPrice.eip1559SurchargeBasis, maxPriorityFeePerGas: 100)
        let warnings = EvmTransactionService.validateGasPrice(recommended: recommended, current: .eip1559(maxFeePerGas: 1000, maxPriorityFeePerGas: tips))
        #expect(warnings.map(\.titledCaution) == expected.map(\.titledCaution))
    }

    @Test func eip1559MaxFeeCanLimitOtherwiseSafeTips() throws {
        let recommended = GasPrice.eip1559(maxFeePerGas: 100 + GasPrice.eip1559SurchargeBasis, maxPriorityFeePerGas: 100)
        let warnings = EvmTransactionService.validateGasPrice(recommended: recommended, current: .eip1559(maxFeePerGas: 189, maxPriorityFeePerGas: 100))
        let warning = try #require(warnings.first)
        #expect(warnings.count == 1)
        #expect(warning.titledCaution == EvmTransactionService.GasDataWarning.riskOfGettingStuck.titledCaution)
    }

    @Test func unavailableOrMismatchedPricesDoNotWarn() {
        #expect(EvmTransactionService.validateGasPrice(recommended: nil, current: .legacy(gasPrice: 1)).isEmpty)
        #expect(EvmTransactionService.validateGasPrice(recommended: .legacy(gasPrice: 100), current: nil).isEmpty)
        #expect(EvmTransactionService.validateGasPrice(recommended: .legacy(gasPrice: 100), current: .eip1559(maxFeePerGas: 1, maxPriorityFeePerGas: 1)).isEmpty)
    }

    @Test(arguments: [(nil, nil, false), (nil, 7, false), (6, nil, false), (6, 7, true), (7, 7, false), (8, 7, false)] as [(Int?, Int?, Bool)])
    func nonceRejectsOnlyValuesBelowMinimum(nonce: Int?, minimum: Int?, rejected: Bool) {
        let errors = EvmTransactionService.validateNonce(nonce: nonce, minimumNonce: minimum)
        #expect(errors.count == (rejected ? 1 : 0))
        if rejected {
            #expect(errors.first?.caution.type == .error)
            #expect(errors.first?.caution.title == "evm_send_settings.nonce.errors.already_in_use".localized)
            #expect(errors.first?.caution.text == "evm_send_settings.nonce.errors.already_in_use.info".localized)
        }
    }

    @Test(arguments: [
        (EvmTransactionService.GasDataWarning.riskOfGettingStuck, "fee_settings.warning.risk_of_getting_stuck"),
        (.overpricing, "fee_settings.warning.overpricing"),
    ])
    func warningsKeepLocalizedCautions(warning: EvmTransactionService.GasDataWarning, key: String) {
        #expect(warning.titledCaution.type == .warning)
        #expect(warning.titledCaution.title == key.localized)
        #expect(warning.titledCaution.text == "\(key).info".localized)
    }
}
