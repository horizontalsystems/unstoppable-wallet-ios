class MoneroReceiveAddressService: BaseReceiveAddressService {
    var moneroAdapter: MoneroAdapter? { super.adapter as? MoneroAdapter }

    override func dataStatus(_ dataStatus: DataStatus<DepositAddress>, isMainNet: Bool) -> DataStatus<ReceiveAddress> {
        let assetReceiveAddress = super.dataStatus(dataStatus, isMainNet: isMainNet)

        return assetReceiveAddress.map {
            guard let assetReceiveAddress = $0 as? AssetReceiveAddress else {
                return $0
            }

            return MoneroAssetReceiveAddress(subAddresses: moneroAdapter?.usedAddresses, assetReceiveAddress)
        }
    }
}

extension MoneroReceiveAddressService {
    class MoneroAssetReceiveAddress: AssetReceiveAddress {
        let subAddresses: [UsedAddress]?

        init(subAddresses: [UsedAddress]?, _ receive: AssetReceiveAddress) {
            self.subAddresses = subAddresses

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
