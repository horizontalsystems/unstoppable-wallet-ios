import MarketKit
import SwiftUI

class FeeSettingsViewFactory {
    static func createSettingsView(transactionService: ITransactionService, sendViewModel: SendViewModel, feeToken: Token) -> AnyView? {
        switch transactionService {
        case let service as BitcoinTransactionService:
            let view = BitcoinFeeSettingsView(service: service, feeToken: feeToken)
                .environmentObject(sendViewModel)

            return AnyView(ThemeNavigationStack { view })
        case let service as EvmTransactionService:
            guard let blockchainType = sendViewModel.handler?.baseToken.blockchainType else {
                return nil
            }

            if service.isEIP1559Supported {
                let view = Eip1559FeeSettingsView(
                    service: service,
                    blockchainType: blockchainType,
                    feeToken: feeToken
                )
                .environmentObject(sendViewModel)

                return AnyView(ThemeNavigationStack { view })
            } else {
                let view = LegacyFeeSettingsView(
                    service: service,
                    blockchainType: blockchainType,
                    feeToken: feeToken
                )
                .environmentObject(sendViewModel)

                return AnyView(ThemeNavigationStack { view })
            }
        case let service as MoneroTransactionService:
            let view = MoneroFeeSettingsView(
                service: service,
                feeToken: feeToken,
            )
            .environmentObject(sendViewModel)

            return AnyView(ThemeNavigationStack { view })
        default: return nil
        }
    }
}
