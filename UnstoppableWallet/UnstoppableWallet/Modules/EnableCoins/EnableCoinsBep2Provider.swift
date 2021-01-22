import RxSwift
import BinanceChainKit

class EnableCoinsBep2Provider {
    private let provider: BinanceChainKit.BinanceAccountProvider

    init(appConfigProvider: IAppConfigProvider) {
        provider = BinanceChainKit.BinanceAccountProvider(networkType: appConfigProvider.testMode ? .testNet : .mainNet)
    }

}

extension EnableCoinsBep2Provider {

    func tokenSymbolsSingle(words: [String]) throws -> Single<[String]> {
        try provider.accountSingle(words: words).map { account in
            account.balances.compactMap { balance in
                balance.free > 0 ? balance.symbol : nil
            }
        }
    }

}
