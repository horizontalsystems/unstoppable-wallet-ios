class CexWithdrawNetworkSelectViewModel {
    private let service: CexWithdrawNetworkSelectService

    let viewItems: [ViewItem]
    let selectedNetworkIndex: Int

    init(service: CexWithdrawNetworkSelectService) {
        self.service = service

        viewItems = service.networks.enumerated().map { index, network in
            ViewItem(
                index: index,
                title: network.networkName,
                imageUrl: network.blockchain?.type.imageUrl,
                enabled: network.enabled
            )
        }

        if let selectedNetwork = service.selectedNetwork {
            selectedNetworkIndex = service.networks
                .enumerated()
                .first { (index, network) in network == selectedNetwork }?
                .offset ?? 0
        } else {
            selectedNetworkIndex = 0
        }
    }

}

extension CexWithdrawNetworkSelectViewModel {

    func onSelect(index: Int) {
        service.select(index: index)
    }

}

extension CexWithdrawNetworkSelectViewModel {

    struct ViewItem {
        let index: Int
        let title: String
        let imageUrl: String?
        let enabled: Bool
    }

}
