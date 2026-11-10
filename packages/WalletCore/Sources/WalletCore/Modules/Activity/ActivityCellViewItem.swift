import Foundation

/// What a row of the Activity lists shows, shared by the transactions and the swap history lists
struct ActivityCellViewItem: Hashable {
    let glyph: String
    let state: State
    /// one token, or two for swap-like rows, shown as "A → B"
    let tokens: [Token]
    let subtitle: String
    let primaryValue: Value?
    let secondaryValue: Value?
    let doubleSpend: Bool
    let locked: Bool?
    /// spam rows are drawn faded
    let dimmed: Bool

    var primaryValueColorStyle: ColorStyle {
        state.valuesMuted ? .secondary : Self.colorStyle(primaryValue?.type ?? .neutral)
    }

    var secondaryValueColorStyle: ColorStyle {
        state.valuesMuted ? .andy : Self.colorStyle(secondaryValue?.type ?? .secondary)
    }

    private static func colorStyle(_ type: ValueType) -> ColorStyle {
        switch type {
        case .incoming: return .green
        case .outgoing, .neutral: return .primary
        case .secondary: return .secondary
        }
    }
}

extension ActivityCellViewItem {
    enum State: Hashable {
        case pending
        case completed
        case failed
        /// a swap that ended without delivering: expired, refunded, unknown
        case inactive
        /// a swap that needs the user: action required
        case attention

        var glyphColorStyle: ColorStyle {
            switch self {
            case .pending, .inactive: return .secondary
            case .completed: return .primary
            case .failed: return .red
            case .attention: return .warning
            }
        }

        var subtitleColorStyle: ColorStyle {
            switch self {
            case .pending: return .andy
            case .completed, .inactive: return .secondary
            case .failed: return .red
            case .attention: return .warning
            }
        }

        var showsRing: Bool {
            self == .pending
        }

        var valuesMuted: Bool {
            switch self {
            case .failed, .inactive, .attention: return true
            case .pending, .completed: return false
            }
        }
    }

    struct Token: Hashable {
        let icon: Icon
        /// the coin code; the type title for rows titled by their chain; `unknownText` for a token the row does not know
        let text: String

        /// fixed by the design, not localized; also the text of an amount that is missing or can't be formatted
        static let unknownText = "------"
        /// a token the row does not know, such as the missing side of a swap
        static let unknown = Token(icon: .unknown, text: unknownText)

        var isUnknown: Bool {
            icon == .unknown
        }
    }

    enum ValueType: Hashable {
        case incoming
        case outgoing
        case neutral
        case secondary
    }

    struct Value: Hashable {
        let text: String
        let type: ValueType
    }
}

extension ActivityCellViewItem.Token {
    enum Icon: Hashable {
        case remote(url: String?, alternativeUrl: String?, placeholder: String, type: IconView.IconType)
        /// a single-colour chain glyph from the asset catalog, e.g. `BlockchainType.iconPlain32`
        case local(name: String)
        /// the placeholder circle of a token the row does not know
        case unknown
    }
}
