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
                        WelcomeScreenView(
                            onCreateWallet: { viewModel.handleIntroFinish() },
                            onAddExistingWallet: { viewModel.handleIntroFinish() }
                        )
                    }
                }
            case .passcodeNotSet:
                NoPasscodeView(mode: .noPasscode)
            case .unknown:
                NoPasscodeView(mode: .cannotCheckPasscode)
            }
        }
        .id(viewModel.brandColor)
        .onOpenURL(perform: { (url: URL) in
            Core.instance?.appManager.didReceive(url: url)
        })
        .preferredColorScheme(viewModel.themeMode.colorScheme)
    }
}
