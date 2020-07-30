import RxSwift
import EthereumKit

class AddErc20TokenInteractor {
    weak var delegate: IAddErc20TokenInteractorDelegate?

    private let coinManager: ICoinManager
    private let pasteboardManager: IPasteboardManager
    private let erc20ContractInfoProvider: IErc20ContractInfoProvider
    private var disposeBag = DisposeBag()

    init(coinManager: ICoinManager, pasteboardManager: IPasteboardManager, erc20ContractInfoProvider: IErc20ContractInfoProvider) {
        self.coinManager = coinManager
        self.pasteboardManager = pasteboardManager
        self.erc20ContractInfoProvider = erc20ContractInfoProvider
    }

}

extension AddErc20TokenInteractor: IAddErc20TokenInteractor {

    var valueFromPasteboard: String? {
        pasteboardManager.value
    }

    func validate(address: String) throws {
        _ = try EthereumKit.Address(hex: address)
    }

    func existingCoin(address: String) -> Coin? {
        coinManager.existingCoin(erc20Address: address)
    }

    func fetchCoin(address: String) {
        erc20ContractInfoProvider.coinSingle(address: address)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(
                        onSuccess: { [weak self] coin in
                            self?.delegate?.didFetch(coin: coin)
                        },
                        onError: { [weak self] error in
                            self?.delegate?.didFailToFetchCoin(error: error)
                        }
                )
                .disposed(by: disposeBag)
    }

    func abortFetchingCoin() {
        disposeBag = DisposeBag()
    }

    func save(coin: Coin) {
        coinManager.save(coin: coin)
    }

}
