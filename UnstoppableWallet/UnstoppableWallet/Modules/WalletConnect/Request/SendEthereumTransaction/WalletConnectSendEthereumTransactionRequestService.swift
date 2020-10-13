import EthereumKit
import RxSwift
import RxRelay
import CurrencyKit
import BigInt

class WalletConnectSendEthereumTransactionRequestService {
    private var ethereumKit: EthereumKit.Kit
    private let appConfigProvider: IAppConfigProvider
    private let currencyKit: ICurrencyKit
    private let rateManager: IRateManager

    private let disposeBag = DisposeBag()

    init(ethereumKit: EthereumKit.Kit, appConfigProvider: IAppConfigProvider, currencyKit: ICurrencyKit, rateManager: IRateManager) {
        self.ethereumKit = ethereumKit
        self.appConfigProvider = appConfigProvider
        self.currencyKit = currencyKit
        self.rateManager = rateManager
    }

}

extension WalletConnectSendEthereumTransactionRequestService {

    var ethereumCoin: Coin {
        appConfigProvider.ethereumCoin
    }

    var ethereumRate: CurrencyValue? {
        let baseCurrency = currencyKit.baseCurrency

        return rateManager.marketInfo(coinCode: ethereumCoin.code, currencyCode: baseCurrency.code).map { marketInfo in
            CurrencyValue(currency: baseCurrency, value: marketInfo.rate)
        }
    }

}
