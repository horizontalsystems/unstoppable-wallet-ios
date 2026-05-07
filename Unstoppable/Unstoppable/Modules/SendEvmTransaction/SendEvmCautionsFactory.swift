class SendEvmCautionsFactory {
    func items(errors: [Error], warnings: [Warning], baseCoinService: CoinService) -> [TitledCaution] {
        var warningCautions = [TitledCaution]()

        for error in errors {
            if let error = error as? EvmFeeModule.GasDataError {
                switch error {
                case .unknownError:
                    return [
                        TitledCaution(
                            title: "alert.unknown_error".localized,
                            text: "",
                            type: .error
                        ),
                    ]
                case .insufficientBalance:
                    return [
                        TitledCaution(
                            title: "fee_settings.errors.insufficient_balance".localized,
                            text: "fee_settings.errors.insufficient_balance.info".localized(baseCoinService.token.coin.code),
                            type: .error
                        ),
                    ]
                }
            } else if let error = error as? NonceService.NonceError {
                return [error.titledCaution]
            } else if let error = error as? UniswapModule.UniswapError {
                switch error {
                case let .forbiddenPriceImpact(provider):
                    return [
                        TitledCaution(title: "swap.price_impact".localized, text: "swap.confirmation.impact_too_high".localized(AppConfig.appName, provider), type: .error),
                    ]
                }
            } else {
                return [convert(error: error, baseCoinService: baseCoinService)]
            }
        }

        for warning in warnings {
            if let warning = warning as? EvmFeeModule.GasDataWarning {
                warningCautions.append(warning.titledCaution)
            } else if let warning = warning as? UniswapModule.UniswapWarning {
                switch warning {
                case .highPriceImpact:
                    warningCautions.append(TitledCaution(title: "swap.price_impact".localized, text: "swap.confirmation.impact_warning".localized, type: .error))
                case .forbiddenPriceImpact:
                    warningCautions.append(TitledCaution(title: "swap.price_impact".localized, text: "swap.confirmation.impact_too_high".localized(AppConfig.appName), type: .error))
                }
            }
        }

        return warningCautions
    }

    private func convert(error: Error, baseCoinService: CoinService) -> TitledCaution {
        var title: String? = nil
        var text: String? = nil

        if case let SendEvmTransactionService.TransactionError.insufficientBalance(requiredBalance) = error {
            let amountData = baseCoinService.amountData(value: requiredBalance)
            title = "fee_settings.errors.insufficient_balance".localized
            text = "ethereum_transaction.error.insufficient_balance".localized(amountData.formattedFull)
        }

        if case let AppError.ethereum(reason) = error.convertedError {
            switch reason {
            case .insufficientBalanceWithFee:
                title = "fee_settings.errors.insufficient_balance".localized
                text = "ethereum_transaction.error.insufficient_balance_with_fee".localized(baseCoinService.token.coin.code)
            case let .executionReverted(message):
                title = "fee_settings.errors.unexpected_error".localized
                text = message
            case .lowerThanBaseGasLimit:
                title = "fee_settings.errors.low_max_fee".localized
                text = "fee_settings.errors.low_max_fee.info".localized
            case .nonceAlreadyInBlock:
                title = "fee_settings.errors.nonce_already_in_block".localized
                text = "ethereum_transaction.error.nonce_already_in_block".localized
            case .replacementTransactionUnderpriced:
                title = "fee_settings.errors.replacement_transaction_underpriced".localized
                text = "ethereum_transaction.error.replacement_transaction_underpriced".localized
            case .transactionUnderpriced:
                title = "fee_settings.errors.transaction_underpriced".localized
                text = "ethereum_transaction.error.transaction_underpriced".localized
            case .tipsHigherThanMaxFee:
                title = "fee_settings.errors.tips_higher_than_max_fee".localized
                text = "ethereum_transaction.error.tips_higher_than_max_fee".localized
            }
        }

        if case let AppError.oneInch(reason) = error.convertedError {
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
