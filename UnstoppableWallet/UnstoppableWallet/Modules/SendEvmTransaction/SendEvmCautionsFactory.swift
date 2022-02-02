class SendEvmCautionsFactory {

    func items(errors: [Error], warnings: [Warning], baseCoinService: CoinService) -> [TitledCaution] {
        var warningCautions = [TitledCaution]()

        for error in errors {
            if let error = error as? EvmFeeModule.GasDataError {
                switch error {
                case .insufficientBalance:
                    return [
                        TitledCaution(
                                title: "fee_settings.errors.insufficient_balance".localized,
                                text: "fee_settings.errors.insufficient_balance.info".localized(baseCoinService.platformCoin.coin.code),
                                type: .error
                        )
                    ]
                }
            } else {
                return [
                    TitledCaution(
                            title: "ethereum_transaction.error.title".localized,
                            text: convert(error: error, baseCoinService: baseCoinService),
                            type: .error
                    )
                ]
            }
        }

        for warning in warnings {
            if let warning = warning as? EvmFeeModule.GasDataWarning {
                switch warning {
                case .riskOfGettingStuck:
                    warningCautions.append(TitledCaution(title: "fee_settings.warning.risk_of_getting_stuck".localized, text: "fee_settings.warning.risk_of_getting_stuck.info".localized, type: .warning))
                case .highBaseFee:
                    warningCautions.append(TitledCaution(title: "fee_settings.warning.high_base_fee".localized, text: "fee_settings.warning.high_base_fee.info".localized, type: .warning))
                case .overpricing:
                    warningCautions.append(TitledCaution(title: "fee_settings.warning.overpricing".localized, text: "fee_settings.warning.overpricing.info".localized, type: .warning))
                }
            } else if let warning = warning as? UniswapModule.UniswapWarning {
                switch warning{
                case .highPriceImpact:
                    warningCautions.append(TitledCaution(title: "swap.price_impact".localized, text: "swap.confirmation.impact_too_high".localized, type: .warning))
                }
            }
        }

        return warningCautions
    }

    private func convert(error: Error, baseCoinService: CoinService) -> String {
        if case SendEvmTransactionService.TransactionError.insufficientBalance(let requiredBalance) = error {
            let amountData = baseCoinService.amountData(value: requiredBalance)
            return "ethereum_transaction.error.insufficient_balance".localized(amountData.formattedString)
        }

        if case AppError.ethereum(let reason) = error.convertedError {
            switch reason {
            case .insufficientBalanceWithFee, .executionReverted: return "ethereum_transaction.error.insufficient_balance_with_fee".localized(baseCoinService.platformCoin.coin.code)
            case .lowerThanBaseGasLimit: return "ethereum_transaction.error.lower_than_base_gas_limit".localized
            }
        }

        if case AppError.oneInch(let reason) = error.convertedError {
            switch reason {
            case .insufficientBalanceWithFee: return "ethereum_transaction.error.insufficient_balance_with_fee".localized(baseCoinService.platformCoin.coin.code)
            case .cannotEstimate: return "swap.one_inch.error.cannot_estimate".localized(baseCoinService.platformCoin.coin.code)
            case .insufficientLiquidity: return "swap.one_inch.error.insufficient_liquidity".localized()
            }
        }

        return error.convertedError.smartDescription
    }

}
