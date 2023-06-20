class CexDepositNetworkSelectService {
    let cexAsset: CexAsset
    let cexNetworks: [CexNetwork]

    init(cexAsset: CexAsset) {
        self.cexAsset = cexAsset

        cexNetworks = cexAsset.networks.filter { $0.depositEnabled }
    }

}
