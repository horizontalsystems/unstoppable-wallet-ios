class StellarReceiveAddressService: BaseReceiveAddressService {
    var stellarAdapter: StellarAdapter? { super.adapter as? StellarAdapter }

    override func dataStatus(_ dataStatus: DataStatus<DepositAddress>, isMainNet: Bool) -> DataStatus<ReceiveAddress> {
        let assetReceiveAddress = super.dataStatus(dataStatus, isMainNet: isMainNet)
        return assetReceiveAddress.map {
            guard let assetAddress = $0 as? AssetReceiveAddress,
                  let stellarAddress = assetAddress.address as? StellarDepositAddress
            else {
                return $0
            }

            return StellarAssetReceiveAddress(activated: stellarAddress.assetActivated, assetAddress)
        }
    }
}

extension StellarReceiveAddressService {
    class StellarAssetReceiveAddress: AssetReceiveAddress {
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
