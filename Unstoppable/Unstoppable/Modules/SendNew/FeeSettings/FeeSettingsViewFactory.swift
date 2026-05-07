import MarketKit
import SwiftUI

class FeeSettingsViewFactory {
    static func createSettingsView(transactionService: ITransactionService, feeData: FeeData, feeToken: Token, currency: Currency, feeTokenRate: Decimal?) -> AnyView? {
        switch transactionService {
        case let service as UtxoTransactionService:
            if case let .bitcoin(params) = feeData {
                let view = UtxoFeeSettingsView(
                    service: service,
                    params: params,
                    feeToken: feeToken,
                    currency: currency,
                    feeTokenRate: feeTokenRate
                )

                return AnyView(view)
            }
        case let service as EvmTransactionService:
            if case let .evm(evmFeeData) = feeData {
                if service.isEIP1559Supported {
                    let view = Eip1559FeeSettingsView(
                        service: service,
                        evmFeeData: evmFeeData,
                        feeToken: feeToken,
                        currency: currency,
                        feeTokenRate: feeTokenRate
                    )

                    return AnyView(view)
                } else {
                    let view = LegacyFeeSettingsView(
                        service: service,
                        evmFeeData: evmFeeData,
                        feeToken: feeToken,
                        currency: currency,
                        feeTokenRate: feeTokenRate
                    )

                    return AnyView(view)
                }
            }
        case let service as MoneroTransactionService:
            if case let .monero(amount, address) = feeData {
                let view = MoneroFeeSettingsView(
                    service: service,
                    amount: amount,
                    address: address,
                    feeToken: feeToken,
                    currency: currency,
                    feeTokenRate: feeTokenRate
                )

                return AnyView(view)
            }
        default: ()
        }

        return nil
    }
}
