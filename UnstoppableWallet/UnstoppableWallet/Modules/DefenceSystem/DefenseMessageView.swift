import SwiftUI

struct DefenseMessageView<Content: View>: View {
    let direction: DefenseMessageModule.Direction
    let state: DefenseMessageModule.State
    let content: () -> Content
    var action: (() -> Void)?

    init(direction: DefenseMessageModule.Direction, state: DefenseMessageModule.State, @ViewBuilder content: @escaping () -> Content, action: (() -> Void)? = nil) {
        self.direction = direction
        self.state = state
        self.content = content
        self.action = action
    }

    var body: some View {
        VStack(spacing: 0) {
            if direction == .bottom {
                DefenceSystemCell()
            }
            BubbleView(direction: direction, color: state.backgroundColor, content: content, action: action)
                .padding(.vertical, .margin8)
            if direction == .top {
                DefenceSystemCell()
            }
        }
    }
}

enum DefenseMessageModule {
    static let animationTime: TimeInterval = 0.3

    enum Direction {
        case top
        case bottom
    }
    
    enum System: String {
        case send
        case swap
        case walletConnect = "wallet_connect"
    }
    
    enum ActionType {
        case arrow(CustomStringConvertible)
    }
    
    enum State: Int {
        case loading
        case positive
        case attention
        case negative
        case notAvailable
        
        var image: String? {
            switch self {
            case .loading:
                return nil
            case .notAvailable:
                return "close_e_filled"
            case .positive:
                return "shield_check_filled"
            case .attention, .negative:
                return "warning_filled"
            }
        }

        var foregroundColor: Color {
            switch self {
            case .loading:
                return .themeLeah
            case .notAvailable:
                return .white
            case .positive:
                return .black
            case .attention:
                return .black
            case .negative:
                return .white
            }
        }

        var backgroundColor: Color {
            switch self {
            case .loading:
                return .themeAndy
            case .notAvailable:
                return .themeGray
            case .positive:
                return .themeGreen
            case .attention:
                return .themeYellow
            case .negative:
                return .themeLucian
            }
        }
        
        var uid: String {
            switch self {
            case .loading:
                return "loading"
            case .notAvailable:
                return "not_available"
            case .positive:
                return "positive"
            case .attention:
                return "attention"
            case .negative:
                return "negative"
            }
        }
    }
}
