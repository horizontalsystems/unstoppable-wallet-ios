import Foundation
import UIKit
import ThemeKit
import EthereumKit
import CoinKit

struct SendEvmData {
    let transactionData: TransactionData
    let additionalInfo: AdditionInfo?

    enum AdditionInfo {
        case send(info: SendInfo)
        case uniswap(info: SwapInfo)
        case oneInchSwap(info: OneInchSwapInfo)

        var sendInfo: SendInfo? {
            if case .send(let info) = self { return info } else { return nil }
        }

        var swapInfo: SwapInfo? {
            if case .uniswap(let info) = self { return info } else { return nil }
        }

        var oneInchSwapInfo: OneInchSwapInfo? {
            if case .oneInchSwap(let info) = self { return info } else { return nil }
        }
    }

    struct SendInfo {
        let domain: String?
    }

    struct SwapInfo {
        let estimatedOut: Decimal
        let estimatedIn: Decimal
        let slippage: String?
        let deadline: String?
        let recipientDomain: String?
        let price: String?
        let priceImpact: String?
    }

    struct OneInchSwapInfo {
        let coinTo: Coin
        let estimatedAmountTo: Decimal
        let slippage: String?
        let recipientDomain: String?
    }

}

struct SendEvmConfirmationModule {

    static func viewController(evmKit: EthereumKit.Kit, sendData: SendEvmData) -> UIViewController? {
        let feeCoin: Coin?

        switch evmKit.networkType {
        case .ethMainNet, .ropsten, .rinkeby, .kovan, .goerli: feeCoin = App.shared.coinKit.coin(type: .ethereum)
        case .bscMainNet: feeCoin = App.shared.coinKit.coin(type: .binanceSmartChain)
        }

        guard let coin = feeCoin, let feeRateProvider = App.shared.feeRateProviderFactory.provider(coinType: coin.type) else {
            return nil
        }

        let coinServiceFactory = EvmCoinServiceFactory(baseCoin: coin, coinKit: App.shared.coinKit, currencyKit: App.shared.currencyKit, rateManager: App.shared.rateManager)
        let transactionService = EvmTransactionService(evmKit: evmKit, feeRateProvider: feeRateProvider)
        let service = SendEvmTransactionService(sendData: sendData, evmKit: evmKit, transactionService: transactionService, activateCoinManager: App.shared.activateCoinManager)

        let transactionViewModel = SendEvmTransactionViewModel(service: service, coinServiceFactory: coinServiceFactory)
        let feeViewModel = EthereumFeeViewModel(service: transactionService, coinService: coinServiceFactory.baseCoinService)

        return SendEvmConfirmationViewController(transactionViewModel: transactionViewModel, feeViewModel: feeViewModel)
    }

}
