class TronReceiveAddressService: BaseReceiveAddressService {
    var tronAdapter: TronAdapter? { super.adapter as? TronAdapter }

    override func dataStatus(_ dataStatus: DataStatus<DepositAddress>, isMainNet: Bool) -> DataStatus<ReceiveAddress> {
        let assetReceiveAddress = super.dataStatus(dataStatus, isMainNet: isMainNet)
        return assetReceiveAddress.map {
            guard let assetAddress = $0 as? AssetReceiveAddress,
                  let tronAddress = assetAddress.address as? ActivatedDepositAddress
            else {
                return $0
            }

            return TronAssetReceiveAddress(activated: tronAddress.isActive, assetAddress)
        }
    }
}

extension TronReceiveAddressService {
    class TronAssetReceiveAddress: AssetReceiveAddress {
        let activated: Bool

        init(activated: Bool, _ receive: AssetReceiveAddress) {
            self.activated = activated

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
