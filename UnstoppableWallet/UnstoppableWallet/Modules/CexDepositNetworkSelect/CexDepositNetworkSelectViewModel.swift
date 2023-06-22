class CexDepositNetworkSelectViewModel {
    private let service: CexDepositNetworkSelectService

    let viewItems: [ViewItem]

    init(service: CexDepositNetworkSelectService) {
        self.service = service

        viewItems = service.cexNetworks.map { cexNetwork in
            ViewItem(
                    cexNetwork: cexNetwork,
                    title: cexNetwork.networkName,
                    imageUrl: cexNetwork.blockchain?.type.imageUrl
            )
        }
    }

}

extension CexDepositNetworkSelectViewModel {

    var cexAsset: CexAsset {
        service.cexAsset
    }

}

extension CexDepositNetworkSelectViewModel {

    struct ViewItem {
        let cexNetwork: CexNetwork
        let title: String
        let imageUrl: String?
    }

}
