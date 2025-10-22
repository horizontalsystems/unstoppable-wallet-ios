class ZCashReceiveAddressService: BaseReceiveAddressService {
    var zcashAdapter: ZcashAdapter? { super.adapter as? ZcashAdapter }

    let addressType: ZcashAdapter.AddressType

    init(wallet: Wallet, addressType: ZcashAdapter.AddressType) {
        self.addressType = addressType

        super.init(wallet: wallet)
    }

    override func dataStatus(_ dataStatus: DataStatus<DepositAddress>, isMainNet: Bool) -> DataStatus<ReceiveAddress> {
        dataStatus.map { address in
            var resolvedAddress = address
            switch addressType {
            case .shielded:
                if let uAddress = zcashAdapter?.uAddress {
                    resolvedAddress = .init(uAddress.stringEncoded)
                }
            case .transparent:
                if let tAddress = zcashAdapter?.tAddress {
                    resolvedAddress = .init(tAddress.stringEncoded)
                }
            }
            return AssetReceiveAddress(
                address: resolvedAddress,
                token: wallet.token,
                isMainNet: isMainNet,
                watchAccount: wallet.account.watchAccount,
                coinCode: wallet.coin.code,
                imageUrl: wallet.coin.imageUrl
            )
        }
    }
}
