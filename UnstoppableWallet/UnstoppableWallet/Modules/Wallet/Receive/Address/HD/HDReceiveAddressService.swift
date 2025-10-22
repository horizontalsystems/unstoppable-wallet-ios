class HDReceiveAddressService: BaseReceiveAddressService {
    var hdAdapter: IHDDepositAdapter? { super.adapter as? IHDDepositAdapter }

    override func dataStatus(_ dataStatus: DataStatus<DepositAddress>, isMainNet: Bool) -> DataStatus<ReceiveAddress> {
        var usedAddresses = [HDReceiveAddressViewModel.AddressChain: [UsedAddress]]()
        if let used = hdAdapter?.usedAddresses(change: false), !used.isEmpty {
            usedAddresses[.external] = used
        }
        if let used = hdAdapter?.usedAddresses(change: true), !used.isEmpty {
            usedAddresses[.change] = used
        }

        let assetReceiveAddress = super.dataStatus(dataStatus, isMainNet: isMainNet)

        return assetReceiveAddress.map {
            guard let assetReceiveAddress = $0 as? AssetReceiveAddress else {
                return $0
            }

            return HDAssetReceiveAddress(usedAddresses: usedAddresses, assetReceiveAddress)
        }
    }
}

extension HDReceiveAddressService {
    class HDAssetReceiveAddress: AssetReceiveAddress {
        let usedAddresses: [HDReceiveAddressViewModel.AddressChain: [UsedAddress]]?

        init(usedAddresses: [HDReceiveAddressViewModel.AddressChain: [UsedAddress]]?, _ receive: AssetReceiveAddress) {
            self.usedAddresses = usedAddresses

            super.init(
                address: receive.address,
                token: receive.token,
                isMainNet: receive.isMainNet,
                watchAccount: receive.watchAccount,
                coinCode: receive.coinCode,
                imageUrl: receive.imageUrl
            )
        }
    }
}
