enum CustomPriorityUnit: String {
    case satoshi = "sat/byte"
    case gwei = "gwei"

    var presentationDecimals: Int {
        switch self {
        case .satoshi: return 0
        case .gwei: return 9
        }
    }

    var presentationName: String {
        self.rawValue
    }

}
