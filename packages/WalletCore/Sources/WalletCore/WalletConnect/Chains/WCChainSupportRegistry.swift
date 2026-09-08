class WCChainSupportRegistry {
    private var supports = [IWCChainSupport]()

    func register(_ support: IWCChainSupport) {
        supports.append(support)
    }

    func support(namespace: String) -> IWCChainSupport? {
        supports.first { $0.namespace == namespace }
    }
}
