import SwiftUI

struct RightChecking: ViewModifier {
    @Binding var state: State

    init(state: Binding<State>) {
        _state = state
    }

    func body(content: Content) -> some View {
        HStack(spacing: .margin8) {
            content

            switch state {
            case .idle: EmptyView()
            case .loading: ProgressView()
            case .checked:
                Image("circle_check_20")
                    .renderingMode(.template)
                    .foregroundColor(.themeRemus)
            }
        }
    }
}

extension RightChecking {
    enum State {
        case idle, loading, checked
    }
}
