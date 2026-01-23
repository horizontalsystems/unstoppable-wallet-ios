import Combine
import ZcashLightClientKit

class ZCashReceiveAddressService: BaseReceiveAddressService {
    var zcashAdapter: ZcashAdapter? { super.adapter as? ZcashAdapter }

    private var cancellables = Set<AnyCancellable>()

    let addressType: ZcashAdapter.ReceiveAddressType
    private var resolvedAddress: String?

    private var addressesSubject = PassthroughSubject<[SingleUseAddress], Never>()
    var addressesPublisher: AnyPublisher<[SingleUseAddress], Never> {
        addressesSubject.eraseToAnyPublisher()
    }

    init(wallet: Wallet, addressType: ZcashAdapter.ReceiveAddressType) {
        self.addressType = addressType
        super.init(wallet: wallet)

        if let zcashAdapter, addressType == .singleUseTransparent {
            zcashAdapter
                .singleUseAddressManager
                .handleNewUsedAddressPublisher
                .sink(receiveValue: { [weak self] in
                    self?.handleNewUsedAddress(address: $0)
                }).store(in: &cancellables)
        }
    }

    override func prepare(adapter: IDepositAdapter) {
        guard let zcashAdapter = adapter as? ZcashAdapter else {
            super.prepare(adapter: adapter)
            return
        }

        clearCancellables()

        switch addressType {
        case .shielded:
            updateUnified(adapter: zcashAdapter)

        case .transparent:
            updateTransparent(adapter: zcashAdapter)

        case .singleUseTransparent:
            updateSingleUse(adapter: zcashAdapter)
        }
    }

    private func handleNewUsedAddress(address _: SingleUseAddress) {
        if let zcashAdapter {
            updateSingleUse(adapter: zcashAdapter)
        }
    }

    private func updateAddresses(_ addresses: [SingleUseAddress]) {
        addressesSubject.send(addresses)
    }

    private func updateUnified(adapter: ZcashAdapter) {
        // Load custom unified address for shielded or fallback on first address
        Task { [weak self, weak adapter] in
            guard let self, let adapter else { return }

            if let unifiedAddress = await (try? adapter.getCustomUnifiedAddress())?.stringEncoded ?? adapter.tAddress?.stringEncoded {
                await MainActor.run {
                    self.resolvedAddress = unifiedAddress
                    self.updateState(isMainNet: adapter.isMainNet)
                }
            }
        }
        resolvedAddress = adapter.uAddress?.stringEncoded
        updateState(isMainNet: adapter.isMainNet)
    }

    private func updateTransparent(adapter: ZcashAdapter) {
        Task { [weak self, weak adapter] in
            guard let self, let adapter else { return }

            if let transparent = adapter.tAddress?.stringEncoded {
                await MainActor.run {
                    self.resolvedAddress = transparent
                    self.updateState(isMainNet: adapter.isMainNet)
                }
            } else {
                resolvedAddress = "n/a".localized
            }
        }
    }

    private func updateSingleUse(adapter: ZcashAdapter) {
        Task { [weak self, weak adapter] in
            guard let self, let adapter else { return }

            let firstUnused = try? adapter.singleUseAddressManager.firstUnused()?.address
            if let transparent = firstUnused ?? adapter.tAddress?.stringEncoded {
                await MainActor.run {
                    self.resolvedAddress = transparent
                    self.updateState(isMainNet: adapter.isMainNet)
                }
            } else {
                resolvedAddress = "n/a".localized
            }
        }
    }

    private func updateState(isMainNet: Bool) {
        let status = resolvedAddress.map { DataStatus.completed(DepositAddress($0)) }
        handleStatus(status: status ?? .loading, isMainNet: isMainNet)
    }
}
