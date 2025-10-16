import Combine
import Foundation
import HsExtensions
import MarketKit
import RxCocoa
import RxSwift

class ReceiveAddressService {
    let wallet: Wallet
    private let type: DepositAddressType
    private let adapterManager: AdapterManager

    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    private(set) var state: DataStatus<ReceiveAddress> = .loading {
        didSet {
            stateUpdatedSubject.send(state)
        }
    }

    private let stateUpdatedSubject = PassthroughSubject<DataStatus<ReceiveAddress>, Never>()

    var adapter: IDepositAdapter?

    init(wallet: Wallet, type: DepositAddressType, adapterManager: AdapterManager) {
        self.wallet = wallet
        self.type = type
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
        for cancellable in cancellables {
            cancellable.cancel()
        }
        cancellables.removeAll()

        let isMainNet = adapter.isMainNet
        let type = type

        adapter.receiveAddressPublisher
            .sink { [weak self, weak adapter] _ in
                var usedAddresses = [ReceiveAddressModule.AddressChain: [UsedAddress]]()
                usedAddresses[.external] = adapter?.usedAddresses(change: false) ?? []
                usedAddresses[.change] = adapter?.usedAddresses(change: true) ?? []

                let receiveAddress = adapter?.allAddresses[type] ?? adapter?.receiveAddress ?? DepositAddress("n/a".localized)
                self?.updateStatus(address: receiveAddress, usedAddresses: usedAddresses, isMainNet: isMainNet)
            }
            .store(in: &cancellables)

        var usedAddresses = [ReceiveAddressModule.AddressChain: [UsedAddress]]()
        usedAddresses[.external] = adapter.usedAddresses(change: false)
        usedAddresses[.change] = adapter.usedAddresses(change: true)

        let receiveAddress = adapter.allAddresses[type] ?? adapter.receiveAddress
        updateStatus(address: receiveAddress, usedAddresses: usedAddresses, isMainNet: isMainNet)
    }

    private func updateStatus(address: DepositAddress, usedAddresses: [ReceiveAddressModule.AddressChain: [UsedAddress]]?, isMainNet: Bool) {
        state = .completed(
            AssetReceiveAddress(
                address: address,
                usedAddresses: usedAddresses,
                token: wallet.token,
                isMainNet: isMainNet,
                watchAccount: wallet.account.watchAccount,
                coinCode: wallet.coin.code,
                imageUrl: wallet.coin.imageUrl,
                caution: type.caution
            )
        )
    }
}

extension ReceiveAddressService: IReceiveAddressService {
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

extension ReceiveAddressService {
    class AssetReceiveAddress: ReceiveAddress {
        let address: DepositAddress
        let usedAddresses: [ReceiveAddressModule.AddressChain: [UsedAddress]]?
        let token: Token
        let isMainNet: Bool
        let watchAccount: Bool
        let caution: CautionNew?

        init(address: DepositAddress, usedAddresses: [ReceiveAddressModule.AddressChain: [UsedAddress]]?, token: Token, isMainNet: Bool, watchAccount: Bool, coinCode: String, imageUrl: String, caution: CautionNew?) {
            self.address = address
            self.usedAddresses = usedAddresses
            self.token = token
            self.isMainNet = isMainNet
            self.watchAccount = watchAccount
            self.caution = caution
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

extension ReceiveAddressService: ICurrentAddressProvider {
    var address: String? {
        guard let receiveAddress = state.data, let assetReceiveAddress = receiveAddress as? AssetReceiveAddress else {
            return nil
        }

        return assetReceiveAddress.raw
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
