enum WCVerificationVerdict: Equatable {
    case pass
    case caution(reason: WCVerdictReason)
    case block(reason: WCVerdictReason)

    private var severity: Int {
        switch self {
        case .pass: return 0
        case .caution: return 1
        case .block: return 2
        }
    }

    static func worst(_ verdicts: [WCVerificationVerdict]) -> WCVerificationVerdict {
        verdicts.max { $0.severity < $1.severity } ?? .pass
    }
}
