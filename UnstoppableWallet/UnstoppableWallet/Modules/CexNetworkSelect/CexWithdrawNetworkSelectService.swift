import HsExtensions

class CexWithdrawNetworkSelectService {
    let cexNetworks: [CexNetwork]

    @PostPublished private(set) var selectedNetwork: CexNetwork?

    init(cexNetworks: [CexNetwork], defaultNetwork: CexNetwork?) {
        self.cexNetworks = cexNetworks
        selectedNetwork = defaultNetwork
    }

}

extension CexWithdrawNetworkSelectService {

    func select(index: Int) {
        if let network = cexNetworks.at(index: index) {
            selectedNetwork = network
        }
    }

}
