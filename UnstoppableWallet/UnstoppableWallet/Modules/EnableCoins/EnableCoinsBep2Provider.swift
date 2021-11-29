import RxSwift
import BinanceChainKit

class EnableCoinsBep2Provider {
    private let provider: BinanceChainKit.BinanceAccountProvider

    init(appConfigProvider: AppConfigProvider) {
        provider = BinanceChainKit.BinanceAccountProvider(networkType: appConfigProvider.testMode ? .testNet : .mainNet)
    }

}

extension EnableCoinsBep2Provider {

    func tokenSymbolsSingle(seed: Data) throws -> Single<[String]> {
        try provider.accountSingle(seed: seed)
            .map({ account in
                account.balances.compactMap { balance in
                    balance.free > 0 ? balance.symbol : nil
                }
            })
            .catchError({ _ in return Single.just([]) })
    }

}
