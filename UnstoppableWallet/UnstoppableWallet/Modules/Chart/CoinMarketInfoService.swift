import UIKit
import RxSwift
import RxCocoa
import XRatesKit
import CoinKit
import CurrencyKit

class CoinMarketInfoService {
    private static let timePeriods: [TimePeriod] = [.day7, .day30]

    private var disposeBag = DisposeBag()

    private let coinKit: CoinKit.Kit
    private let rateManager: IRateManager
    private let currencyKit: ICurrencyKit
    private let coinType: CoinType

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(coinKit: CoinKit.Kit, rateManager: IRateManager, currencyKit: ICurrencyKit, coinType: CoinType) {
        self.coinKit = coinKit
        self.rateManager = rateManager
        self.currencyKit = currencyKit
        self.coinType = coinType

        fetchChartData()
    }

    private func fetchChartData() {
        disposeBag = DisposeBag()
        state = .loading

        let coinMarketInfo = rateManager.coinMarketInfoSingle(
                coinType: coinType,
                currencyCode: currencyKit.baseCurrency.code,
                rateDiffTimePeriods: Self.timePeriods,
                rateDiffCoinCodes: diffCoinCodes
        )

        coinMarketInfo
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: { [weak self] coinMarketInfo in
                    self?.state = .loaded(info: coinMarketInfo)
                }, onError: { [weak self] error in
                    self?.state = .error(error)
                })
                .disposed(by: disposeBag)
    }

    private var diffCoinCodes: [String] {
        [coinKit.coin(type: .bitcoin), coinKit.coin(type: .ethereum)].compactMap { $0?.code }
    }

}

extension CoinMarketInfoService {

    enum State {
        case loading
        case loaded(info: CoinMarketInfo)
        case error(Error)
    }

}