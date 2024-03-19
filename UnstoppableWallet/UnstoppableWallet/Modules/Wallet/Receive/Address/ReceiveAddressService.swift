import Combine
import Foundation
import HsExtensions
import MarketKit
import RxCocoa
import RxSwift

class ReceiveAddressService {
    typealias ServiceItem = Item

    private let adapterManager: AdapterManager
    private let wallet: Wallet

    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    private(set) var state: DataStatus<Item> = .loading {
        didSet {
            stateUpdatedSubject.send(state)
        }
    }

    private let stateUpdatedSubject = PassthroughSubject<DataStatus<Item>, Never>()

    private var adapter: IDepositAdapter?

    init(wallet: Wallet, adapterManager: AdapterManager) {
        self.wallet = wallet
        self.adapterManager = adapterManager

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
        cancellables.forEach { cancellable in
            cancellable.cancel()
        }
        cancellables.removeAll()

        let isMainNet = adapter.isMainNet
        adapter.receiveAddressPublisher
            .sink { [weak self, weak adapter] status in
                var usedAddresses = [ReceiveAddressModule.AddressType: [UsedAddress]]()
                usedAddresses[.external] = adapter?.usedAddresses(change: false) ?? []
                usedAddresses[.change] = adapter?.usedAddresses(change: true) ?? []

                self?.updateStatus(status: status, usedAddresses: usedAddresses, isMainNet: isMainNet)
            }
            .store(in: &cancellables)

        var usedAddresses = [ReceiveAddressModule.AddressType: [UsedAddress]]()
        usedAddresses[.external] = adapter.usedAddresses(change: false)
        usedAddresses[.change] = adapter.usedAddresses(change: true)

        updateStatus(status: adapter.receiveAddressStatus, usedAddresses: usedAddresses, isMainNet: isMainNet)
    }

    private func updateStatus(status: DataStatus<DepositAddress>, usedAddresses: [ReceiveAddressModule.AddressType: [UsedAddress]]?, isMainNet: Bool) {
        state = status.map { address in
            Item(
                address: address,
                usedAddresses: usedAddresses,
                token: wallet.token,
                isMainNet: isMainNet,
                watchAccount: wallet.account.watchAccount,
                coinCode: wallet.coin.code,
                imageUrl: wallet.coin.imageUrl
            )
        }
    }
}

extension ReceiveAddressService: IReceiveAddressService {
    var title: String {
        "deposit.receive_coin".localized(wallet.coin.code)
    }

    var coinName: String {
        wallet.coin.name
    }

    var statusUpdatedPublisher: AnyPublisher<DataStatus<ServiceItem>, Never> {
        stateUpdatedSubject.eraseToAnyPublisher()
    }
}

extension ReceiveAddressService {
    struct Item {
        let address: DepositAddress
        let usedAddresses: [ReceiveAddressModule.AddressType: [UsedAddress]]?
        let token: Token
        let isMainNet: Bool
        let watchAccount: Bool
        let coinCode: String
        let imageUrl: String?
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
