import RxSwift
import RxRelay
import MarketKit

class CoinMajorHoldersService {
    let coin: Coin
    let blockchain: Blockchain
    private let marketKit: Kit
    private let evmLabelManager: EvmLabelManager
    private var disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<DataStatus<TokenHolders>>()
    private(set) var state: DataStatus<TokenHolders> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(coin: Coin, blockchain: Blockchain, marketKit: Kit, evmLabelManager: EvmLabelManager) {
        self.coin = coin
        self.blockchain = blockchain
        self.marketKit = marketKit
        self.evmLabelManager = evmLabelManager

        sync()
    }

    private func sync() {
        disposeBag = DisposeBag()

        state = .loading

        marketKit.tokenHoldersSingle(coinUid: coin.uid, blockchainUid: blockchain.uid)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] holders in
                    self?.state = .completed(holders)
                }, onError: { [weak self] error in
                    self?.state = .failed(error)
                })
                .disposed(by: disposeBag)
    }

}

extension CoinMajorHoldersService {

    var stateObservable: Observable<DataStatus<TokenHolders>> {
        stateRelay.asObservable()
    }

    func labeled(address: String) -> String {
        evmLabelManager.mapped(address: address)
    }

    func refresh() {
        sync()
    }

}
