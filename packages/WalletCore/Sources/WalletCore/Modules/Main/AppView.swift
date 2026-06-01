import SwiftUI

public struct AppView: View {
    @StateObject var viewModel = AppViewModel()

    public init() {}

    public var body: some View {
        Group {
            switch viewModel.passcodeLockState {
            case .passcodeSet:
                ZStack {
                    MainView()
                        .modifier(CoordinatorViewModifier())

                    if viewModel.introVisible {
                        WelcomeScreenView {
                            viewModel.handleIntroFinish()
                        }
                        .ignoresSafeArea()
                    }
                }
            case .passcodeNotSet:
                NoPasscodeView(mode: .noPasscode)
            case .unknown:
                NoPasscodeView(mode: .cannotCheckPasscode)
            }
        }
        .onOpenURL(perform: { (url: URL) in
            Core.instance?.appManager.didReceive(url: url)
        })
        .preferredColorScheme(viewModel.themeMode.colorScheme)
    }
}
