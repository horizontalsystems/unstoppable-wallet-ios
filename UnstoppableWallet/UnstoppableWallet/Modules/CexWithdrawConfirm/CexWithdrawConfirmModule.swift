import Foundation
import UIKit
import ComponentKit

protocol ICexWithdrawHandler {
    associatedtype WithdrawResult

    func withdraw(id: String, network: String?, address: String, amount: Decimal, feeFromAmount: Bool?) async throws -> WithdrawResult
    func handle(result: WithdrawResult, viewController: UIViewController)
}

struct CexWithdrawConfirmModule {

    static func viewController(sendData: CexWithdrawModule.SendData) -> UIViewController? {
        guard let account = App.shared.accountManager.activeAccount else {
            return nil
        }

        guard case .cex(let type) = account.type else {
            return nil
        }

        let contactLabelService = sendData.network?.blockchain.map {
            ContactLabelService(contactManager: App.shared.contactManager, blockchainType: $0.type)
        }
        let networkManager = App.shared.networkManager

        switch type {
            case .binance(let apiKey, let secret):
                let provider = BinanceCexProvider(networkManager: networkManager, apiKey: apiKey, secret: secret)
                let handler = BinanceWithdrawHandler(provider: provider)
                let service = CexWithdrawConfirmService(sendData: sendData, handler: handler)
                let coinService = CexCoinService(cexAsset: sendData.cexAsset, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
                let viewModel = CexWithdrawConfirmViewModel(service: service, coinService: coinService, contactLabelService: contactLabelService)
                return CexWithdrawConfirmViewController(viewModel: viewModel, handler: handler)

            case .coinzix(let authToken, let secret):
                let provider = CoinzixCexProvider(networkManager: networkManager, authToken: authToken, secret: secret)
                let handler = CoinzixWithdrawHandler(provider: provider)
                let service = CexWithdrawConfirmService(sendData: sendData, handler: handler)
                let coinService = CexCoinService(cexAsset: sendData.cexAsset, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
                let viewModel = CexWithdrawConfirmViewModel(service: service, coinService: coinService, contactLabelService: contactLabelService)
                return CexWithdrawConfirmViewController(viewModel: viewModel, handler: handler)
        }
    }

}
