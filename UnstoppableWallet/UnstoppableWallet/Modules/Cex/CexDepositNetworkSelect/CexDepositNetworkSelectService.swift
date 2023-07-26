class CexDepositNetworkSelectService {
    let cexAsset: CexAsset
    let networks: [CexDepositNetwork]

    init(cexAsset: CexAsset) {
        self.cexAsset = cexAsset

        networks = cexAsset.depositNetworks
    }

}
