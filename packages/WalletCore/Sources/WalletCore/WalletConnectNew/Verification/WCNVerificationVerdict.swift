enum WCNVerificationVerdict: Equatable {
    case pass
    case caution(reason: WCNVerdictReason)
    case block(reason: WCNVerdictReason)

    private var severity: Int {
        switch self {
        case .pass: return 0
        case .caution: return 1
        case .block: return 2
        }
    }

    static func worst(_ verdicts: [WCNVerificationVerdict]) -> WCNVerificationVerdict {
        verdicts.max { $0.severity < $1.severity } ?? .pass
    }
}
