/// Receive state for XRP tokens (StellarReceiveAddressService form). Only an issued token can be
/// activated from the wallet, by a TrustSet; an unfunded account is activated by its first
/// deposit and shows the plain receive screen, as on Android.
class XrpReceiveAddressService: BaseReceiveAddressService {
    override func dataStatus(_ dataStatus: DataStatus<DepositAddress>, isMainNet: Bool) -> DataStatus<ReceiveAddress> {
        let assetReceiveAddress = super.dataStatus(dataStatus, isMainNet: isMainNet)
        return assetReceiveAddress.map {
            guard let assetAddress = $0 as? AssetReceiveAddress,
                  let xrpAddress = assetAddress.address as? XrpDepositAddress,
                  let activationSendData = xrpAddress.activationSendData
            else {
                return $0
            }

            return XrpAssetReceiveAddress(activated: xrpAddress.activated, activationSendData: activationSendData, assetAddress)
        }
    }
}

extension XrpReceiveAddressService {
    class XrpAssetReceiveAddress: AssetReceiveAddress {
        let activated: Bool
        let activationSendData: SendData

        init(activated: Bool, activationSendData: SendData, _ receive: AssetReceiveAddress) {
            self.activated = activated
            self.activationSendData = activationSendData

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
