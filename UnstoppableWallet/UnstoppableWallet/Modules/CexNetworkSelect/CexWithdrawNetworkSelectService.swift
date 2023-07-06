import HsExtensions

class CexWithdrawNetworkSelectService {
    let networks: [CexWithdrawNetwork]

    @PostPublished private(set) var selectedNetwork: CexWithdrawNetwork?

    init(networks: [CexWithdrawNetwork], defaultNetwork: CexWithdrawNetwork?) {
        self.networks = networks
        selectedNetwork = defaultNetwork
    }

}

extension CexWithdrawNetworkSelectService {

    func select(index: Int) {
        if let network = networks.at(index: index) {
            selectedNetwork = network
        }
    }

}
