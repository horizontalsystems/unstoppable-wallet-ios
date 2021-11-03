import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class CoinDetailsService {
    private var disposeBag = DisposeBag()

    private let fullCoin: FullCoin
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit

    private let stateRelay = PublishRelay<DataStatus<MarketInfoDetails>>()
    private(set) var state: DataStatus<MarketInfoDetails> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(fullCoin: FullCoin, marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit) {
        self.fullCoin = fullCoin
        self.marketKit = marketKit
        self.currencyKit = currencyKit
    }

}

extension CoinDetailsService {

    var stateObservable: Observable<DataStatus<MarketInfoDetails>> {
        stateRelay.asObservable()
    }

    var currency: Currency {
        currencyKit.baseCurrency
    }

    var coinUid: String {
        fullCoin.coin.uid
    }

    var auditAddresses: [String] {
        fullCoin.platforms.compactMap { platform in
            switch platform.coinType {
            case .erc20(let address): return address
            case .bep20(let address): return address
            default: return nil
            }
        }
    }

    var majorHoldersErc20Address: String? {
        for platform in fullCoin.platforms {
            switch platform.coinType {
            case .erc20(let address): return address
            default: ()
            }
        }

        return nil
    }

    func sync() {
        disposeBag = DisposeBag()

        state = .loading

        marketKit.marketInfoDetailsSingle(coinUid: fullCoin.coin.uid, currencyCode: currency.code)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] info in
                    self?.state = .completed(info)
                }, onError: { [weak self] error in
                    self?.state = .failed(error)
                })
                .disposed(by: disposeBag)
    }

}
