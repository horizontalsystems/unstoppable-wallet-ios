import SwiftUI

struct AppView: View {
    private static let introShownKey = "introShown"

    @AppStorage(Self.introShownKey) private var introShown = false

    @State private var state: ViewState

    init() {
        let introShown = UserDefaults.standard.bool(forKey: Self.introShownKey)
        _state = State(initialValue: introShown ? .setupWallet : .intro)
    }

    var body: some View {
        ZStack {
            switch state {
            case .intro:
                IntroView {
                    introShown = true
                    state = .setupWallet
                }
            case .setupWallet:
                SetupWalletView()
            case .main:
                MainView()
            }
        }
        .animation(.default, value: state)
    }
}

extension AppView {
    enum ViewState {
        case intro
        case setupWallet
        case main
    }
}
