import SwiftUI

struct DefenseMessageView<Content: View>: View {
    let direction: DefenseMessageModule.Direction
    let state: DefenseMessageModule.State
    let content: () -> Content

    init(direction: DefenseMessageModule.Direction, state: DefenseMessageModule.State, @ViewBuilder content: @escaping () -> Content) {
        self.direction = direction
        self.state = state
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            if direction == .top {
                DefenceSystemCell()
            }
            BubbleView(direction: direction, color: state.backgroundColor, content: content)
                .padding(.vertical, .margin8)
                .padding(.horizontal, .margin16)
            if direction == .bottom {
                DefenceSystemCell()
            }
        }
    }
}

struct DefenseMessageModule {
    static let animationTime: TimeInterval = 0.3

    enum Direction {
        case top
        case bottom
    }

    enum State: Int {
        case loading
        case positive
        case attention
        case negative
        case notAvailable
        
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
    }
}
