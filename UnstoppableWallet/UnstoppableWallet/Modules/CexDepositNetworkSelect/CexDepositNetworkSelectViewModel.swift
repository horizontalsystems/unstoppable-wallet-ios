class CexDepositNetworkSelectViewModel {
    private let service: CexDepositNetworkSelectService

    let viewItems: [ViewItem]

    init(service: CexDepositNetworkSelectService) {
        self.service = service

        viewItems = service.networks.map { network in
            ViewItem(
                    network: network,
                    title: network.networkName,
                    imageUrl: network.blockchain?.type.imageUrl,
                    enabled: network.enabled
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
        let network: CexDepositNetwork
        let title: String
        let imageUrl: String?
        let enabled: Bool
    }

}
