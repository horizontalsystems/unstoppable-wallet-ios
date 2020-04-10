enum EthereumRpcMode: String {
    case infura
    case incubed

    var title: String {
        switch self {
        case .infura: return "Infura"
        case .incubed: return "Incubed"
        }
    }

}
