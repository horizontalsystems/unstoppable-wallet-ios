class CexWithdrawNetworkSelectViewModel {
    private let service: CexWithdrawNetworkSelectService

    let viewItems: [ViewItem]
    let selectedNetworkIndex: Int

    init(service: CexWithdrawNetworkSelectService) {
        self.service = service

        viewItems = service.cexNetworks.enumerated().map { index, cexNetwork in
            ViewItem(
                index: index,
                title: cexNetwork.networkName,
                imageUrl: cexNetwork.blockchain?.type.imageUrl,
                enabled: cexNetwork.withdrawEnabled
            )
        }

        if let selectedNetwork = service.selectedNetwork {
            selectedNetworkIndex = service.cexNetworks
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
