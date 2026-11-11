import Foundation

enum WelcomeTimeline {
    static let final: Step = .legal

    enum Step: Int, CaseIterable, Comparable {
        case initial
        case logoShown
        case logoGone
        case line1
        case line2
        case line3
        case tail
        case secondButton
        case legal

        /// Seconds from the start of the welcome.
        var time: Double {
            switch self {
            case .initial: return 0
            case .logoShown: return 0.35
            case .logoGone: return 2.10
            case .line1: return 2.45
            case .line2: return 2.63
            case .line3: return 2.81
            case .tail: return 3.25
            case .secondButton: return 3.33
            case .legal: return 3.55
            }
        }

        static func < (lhs: Step, rhs: Step) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}
