import Combine
import MarketKit
import RxSwift
import RxCocoa
import HsExtensions

class DepositService {
    private let adapterManager: AdapterManager
    private let wallet: Wallet

    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    @PostPublished var state: DataStatus<Item> = .loading

    private var adapter: IDepositAdapter?

    init(wallet: Wallet, adapterManager: AdapterManager) {
        self.wallet = wallet
        self.adapterManager = adapterManager

        subscribe(disposeBag, adapterManager
                .adapterDataReadyObservable
//                .delay(.seconds(4), scheduler: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
        ) { [weak self] adapterData in
            self?.sync(adapterData: adapterData)
        }

        sync(adapterData: adapterManager.adapterData)
    }

    private func sync(adapterData: AdapterManager.AdapterData) {
        guard let adapter = adapterData.adapterMap[wallet] as? IDepositAdapter else {
            if adapter != nil {
                state = .failed(AdapterError.noAdapter)
            } else {
                state = .loading
            }
            return
        }

        self.adapter = adapter
        prepare(adapter: adapter)
    }

    private func prepare(adapter: IDepositAdapter) {
        cancellables.forEach { cancellable in cancellable.cancel() }
        cancellables.removeAll()

        let isMainNet = adapter.isMainNet
        adapter.receiveAddressPublisher
                .sink { [weak self] status in
                    self?.updateStatus(status: status, isMainNet: isMainNet)
                }
                .store(in: &cancellables)

        updateStatus(status: adapter.receiveAddressStatus, isMainNet: isMainNet)
    }

    private func updateStatus(status: DataStatus<DepositAddress>, isMainNet: Bool) {
        state = status.map { address in Item(address: address, isMainNet: isMainNet) }
    }

}

extension DepositService {

    var coin: Coin {
        wallet.coin
    }

    var token: Token {
        wallet.token
    }

    var watchAccount: Bool {
        wallet.account.watchAccount
    }

    struct Item {
        let address: DepositAddress
        let isMainNet: Bool
    }

}

extension DepositService {

    enum AdapterError: Error {
        case noAdapter
    }

}
