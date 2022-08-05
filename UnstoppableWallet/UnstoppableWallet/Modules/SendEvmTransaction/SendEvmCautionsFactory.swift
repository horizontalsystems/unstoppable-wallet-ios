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
                                text: "fee_settings.errors.insufficient_balance.info".localized(baseCoinService.token.coin.code),
                                type: .error
                        )
                    ]
                case .lowMaxFee:
                    return [
                        TitledCaution(
                                title: "fee_settings.errors.low_max_fee".localized,
                                text: "fee_settings.errors.low_max_fee.info".localized(baseCoinService.token.coin.code),
                                type: .error
                        )
                    ]
                }
            } else {
                return [convert(error: error, baseCoinService: baseCoinService)]
            }
        }

        for warning in warnings {
            if let warning = warning as? EvmFeeModule.GasDataWarning {
                switch warning {
                case .riskOfGettingStuck:
                    warningCautions.append(TitledCaution(title: "fee_settings.warning.risk_of_getting_stuck".localized, text: "fee_settings.warning.risk_of_getting_stuck.info".localized, type: .warning))
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

    private func convert(error: Error, baseCoinService: CoinService) -> TitledCaution {
        var title: String? = nil
        var text: String? = nil

        if case SendEvmTransactionService.TransactionError.insufficientBalance(let requiredBalance) = error {
            let amountData = baseCoinService.amountData(value: requiredBalance)
            title = "fee_settings.errors.insufficient_balance".localized
            text = "ethereum_transaction.error.insufficient_balance".localized(amountData.formattedFull)
        }

        if case AppError.ethereum(let reason) = error.convertedError {
            switch reason {
            case .insufficientBalanceWithFee, .executionReverted:
                title = "fee_settings.errors.insufficient_balance".localized
                text = "ethereum_transaction.error.insufficient_balance_with_fee".localized(baseCoinService.token.coin.code)
            case .lowerThanBaseGasLimit:
                title = "fee_settings.errors.low_max_fee".localized
                text = "fee_settings.errors.low_max_fee.info".localized
            }
        }

        if case AppError.oneInch(let reason) = error.convertedError {
            switch reason {
            case .insufficientBalanceWithFee:
                title = "fee_settings.errors.insufficient_balance".localized
                text = "ethereum_transaction.error.insufficient_balance_with_fee".localized(baseCoinService.token.coin.code)
            case .cannotEstimate:
                title = "swap.one_inch.error.cannot_estimate".localized
                text = "swap.one_inch.error.cannot_estimate.info".localized(baseCoinService.token.coin.code)
            case .insufficientLiquidity:
                text = "swap.one_inch.error.insufficient_liquidity".localized()
                text = "swap.one_inch.error.insufficient_liquidity.info".localized()
            }
        }

        return TitledCaution(
                title: title ?? "ethereum_transaction.error.title".localized,
                text: text ?? error.convertedError.smartDescription,
                type: .error
        )
    }

}
