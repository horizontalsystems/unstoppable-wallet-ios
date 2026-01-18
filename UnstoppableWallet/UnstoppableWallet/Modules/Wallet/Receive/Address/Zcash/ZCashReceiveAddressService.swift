import ZcashLightClientKit

class ZCashReceiveAddressService: BaseReceiveAddressService {
    var zcashAdapter: ZcashAdapter? { super.adapter as? ZcashAdapter }

    let addressType: ZcashAdapter.AddressType
    private var resolvedAddress: String?

    init(wallet: Wallet, addressType: ZcashAdapter.AddressType) {
        self.addressType = addressType
        super.init(wallet: wallet)
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
        }
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
        // Load single-use transparent address asynchronously or fallback on first address
        Task { [weak self, weak adapter] in
            guard let self, let adapter else { return }

            if let transparent = await (try? adapter.getSingleUseTransparentAddress())?.addressString ?? adapter.tAddress?.stringEncoded {
                await MainActor.run {
                    self.resolvedAddress = transparent
                    self.updateState(isMainNet: adapter.isMainNet)
                }
            }
        }
    }

    private func updateState(isMainNet: Bool) {
        let status = resolvedAddress.map { DataStatus.completed(DepositAddress($0)) }
        handleStatus(status: status ?? .loading, isMainNet: isMainNet)
    }
}

// TODO: use public property when sdk will change accessibility
extension SingleUseTransparentAddress {
    var addressString: String? {
        let mirror = Mirror(reflecting: self)
        return mirror.children.first(where: { $0.label == "address" })?.value as? String
    }
}
