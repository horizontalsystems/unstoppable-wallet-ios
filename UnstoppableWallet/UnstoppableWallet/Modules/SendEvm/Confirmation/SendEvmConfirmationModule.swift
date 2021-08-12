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
    private static let forceMultiplier: Double = 1.2

    private static func coin(networkType: NetworkType) -> Coin? {
        switch networkType {
        case .ethMainNet, .ropsten, .rinkeby, .kovan, .goerli: return App.shared.coinKit.coin(type: .ethereum)
        case .bscMainNet: return App.shared.coinKit.coin(type: .binanceSmartChain)
        }
    }

    static func viewController(evmKit: EthereumKit.Kit, sendData: SendEvmData) -> UIViewController? {
        guard let coin = coin(networkType: evmKit.networkType),
              let feeRateProvider = App.shared.feeRateProviderFactory.provider(coinType: coin.type) as? ICustomRangedFeeRateProvider else {
            return nil
        }

        let coinServiceFactory = EvmCoinServiceFactory(baseCoin: coin, coinKit: App.shared.coinKit, currencyKit: App.shared.currencyKit, rateManager: App.shared.rateManager)
        let transactionService = EvmTransactionService(evmKit: evmKit, feeRateProvider: feeRateProvider)
        let service = SendEvmTransactionService(sendData: sendData, evmKit: evmKit, transactionService: transactionService, activateCoinManager: App.shared.activateCoinManager)

        let transactionViewModel = SendEvmTransactionViewModel(service: service, coinServiceFactory: coinServiceFactory)
        let feeViewModel = EthereumFeeViewModel(service: transactionService, coinService: coinServiceFactory.baseCoinService)

        return SendEvmConfirmationViewController(transactionViewModel: transactionViewModel, feeViewModel: feeViewModel)
    }

    static func resendViewController(adapter: ITransactionsAdapter, action: TransactionInfoModule.OptionAction, transactionHash: String) -> UIViewController? {
        guard let adapter = adapter as? EvmTransactionsAdapter,
              let fullTransaction = adapter.evmKit.transaction(hash: Data(hex: transactionHash.stripHexPrefix())),
              let toAddress = fullTransaction.transaction.to else {
            return nil
        }

        let gasPrice = fullTransaction.transaction.gasPrice
        let feeRange = gasPrice...(4 * gasPrice)
        
        guard let coin = coin(networkType: adapter.evmKit.networkType),
              let feeRateProvider = App.shared.feeRateProviderFactory.forcedProvider(coinType: coin.type, customFeeRange: feeRange, multiply: Self.forceMultiplier) else {
            return nil
        }

        let sendData: SendEvmData
        switch action {
        case .speedUp:
            let tx = fullTransaction.transaction
            let transactionData = TransactionData(to: toAddress, value: tx.value, input: tx.input, nonce: tx.nonce)
            sendData = SendEvmData(transactionData: transactionData, additionalInfo: nil)
        case .cancel:
            let tx = fullTransaction.transaction
            let transactionData = TransactionData(to: adapter.evmKit.receiveAddress, value: 0, input: Data(), nonce: tx.nonce)
            sendData = SendEvmData(transactionData: transactionData, additionalInfo: nil)
        }


        let coinServiceFactory = EvmCoinServiceFactory(baseCoin: coin, coinKit: App.shared.coinKit, currencyKit: App.shared.currencyKit, rateManager: App.shared.rateManager)
        let transactionService = EvmTransactionService(evmKit: adapter.evmKit, feeRateProvider: feeRateProvider)
        let service = SendEvmTransactionService(sendData: sendData, evmKit: adapter.evmKit, transactionService: transactionService, activateCoinManager: App.shared.activateCoinManager)

        let transactionViewModel = SendEvmTransactionViewModel(service: service, coinServiceFactory: coinServiceFactory)
        let feeViewModel = EthereumFeeViewModel(service: transactionService, coinService: coinServiceFactory.baseCoinService)

        return SendEvmConfirmationViewController(transactionViewModel: transactionViewModel, feeViewModel: feeViewModel)
    }

}
