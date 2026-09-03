class WCNChainSupportRegistry {
    private var supports = [IWCNChainSupport]()

    func register(_ support: IWCNChainSupport) {
        supports.append(support)
    }

    func support(namespace: String) -> IWCNChainSupport? {
        supports.first { $0.namespace == namespace }
    }
}
