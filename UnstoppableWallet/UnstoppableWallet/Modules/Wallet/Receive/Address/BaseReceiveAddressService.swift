import Combine
import Foundation
import HsExtensions
import MarketKit
import RxCocoa
import RxSwift

class BaseReceiveAddressService {
    private let adapterManager = Core.shared.adapterManager
    let wallet: Wallet

    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    private(set) var state: DataStatus<ReceiveAddress> = .loading {
        didSet {
            stateUpdatedSubject.send(state)
        }
    }

    private let stateUpdatedSubject = PassthroughSubject<DataStatus<ReceiveAddress>, Never>()

    var adapter: IDepositAdapter?

    init(wallet: Wallet) {
        self.wallet = wallet

        subscribe(disposeBag, adapterManager.adapterDataReadyObservable) { [weak self] adapterData in
            self?.sync(adapterData: adapterData)
        }

        sync(adapterData: adapterManager.adapterData)
    }

    private func sync(adapterData: AdapterManager.AdapterData) {
        guard let adapter = adapterData.adapterMap[wallet] as? IDepositAdapter else {
            if adapter != nil {
                state = .failed(ReceiveAddressModule.ErrorItem(icon: "not_available_48", text: AdapterError.noAdapter.localizedDescription))
            } else {
                state = .loading
            }
            return
        }

        self.adapter = adapter
        prepare(adapter: adapter)
    }

    private func prepare(adapter: IDepositAdapter) {
        for cancellable in cancellables {
            cancellable.cancel()
        }
        cancellables.removeAll()

        let isMainNet = adapter.isMainNet
        adapter.receiveAddressPublisher
            .sink { [weak self] status in
                self?.handleStatus(status: status, isMainNet: isMainNet)
            }
            .store(in: &cancellables)

        handleStatus(status: adapter.receiveAddressStatus, isMainNet: isMainNet)
    }

    func handleStatus(status: DataStatus<DepositAddress>, isMainNet: Bool) {
        state = dataStatus(status, isMainNet: isMainNet)
    }

    func dataStatus(_ dataStatus: DataStatus<DepositAddress>, isMainNet: Bool) -> DataStatus<ReceiveAddress> {
        dataStatus.map { address in
            AssetReceiveAddress(
                address: address,
                token: wallet.token,
                isMainNet: isMainNet,
                watchAccount: wallet.account.watchAccount,
                coinCode: wallet.coin.code,
                imageUrl: wallet.coin.imageUrl
            )
        }
    }
}

extension BaseReceiveAddressService: IReceiveAddressService {
    var title: String {
        "deposit.receive_coin".localized(wallet.coin.code)
    }

    var coinName: String {
        wallet.coin.name
    }

    var coinType: MarketKit.BlockchainType {
        wallet.token.blockchainType
    }

    var statusUpdatedPublisher: AnyPublisher<DataStatus<ReceiveAddress>, Never> {
        stateUpdatedSubject.eraseToAnyPublisher()
    }
}

extension BaseReceiveAddressService {
    class AssetReceiveAddress: ReceiveAddress {
        let address: DepositAddress
        let token: Token
        let isMainNet: Bool
        let watchAccount: Bool

        init(address: DepositAddress, token: Token, isMainNet: Bool, watchAccount: Bool, coinCode: String, imageUrl: String?) {
            self.address = address
            self.token = token
            self.isMainNet = isMainNet
            self.watchAccount = watchAccount
            super.init(coinCode: coinCode, imageUrl: imageUrl)
        }

        override var raw: String { address.address }
    }

    enum AdapterError: LocalizedError {
        case noAdapter

        var errorDescription: String? {
            switch self {
            case .noAdapter: return "deposit.no_adapter.error".localized
            }
        }
    }
}

extension BaseReceiveAddressService: ICurrentAddressProvider {
    var address: String? {
        guard let receiveAddress = state.data, let assetReceiveAddress = receiveAddress as? AssetReceiveAddress else {
            return nil
        }

        return assetReceiveAddress.address.address
    }
}

class ReceiveAddress {
    let coinCode: String
    let imageUrl: String?

    init(coinCode: String, imageUrl: String?) {
        self.coinCode = coinCode
        self.imageUrl = imageUrl
    }

    var raw: String { fatalError("must be overridden") }
}
