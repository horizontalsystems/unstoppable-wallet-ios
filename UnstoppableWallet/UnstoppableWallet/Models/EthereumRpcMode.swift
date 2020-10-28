enum EthereumRpcMode: String, CaseIterable {
    case infura
//    case incubed

    var title: String {
        switch self {
        case .infura: return "Infura"
//        case .incubed: return "Incubed"
        }
    }

    var address: String {
        switch self {
        case .infura: return "infura.io"
//        case .incubed: return "slock.it"
        }
    }

}
