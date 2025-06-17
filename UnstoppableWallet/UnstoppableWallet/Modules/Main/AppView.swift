import SwiftUI

struct AppView: View {
    @StateObject var viewModel = AppViewModel()

    var body: some View {
        Group {
            switch viewModel.passcodeLockState {
            case .passcodeSet:
                ZStack {
                    MainView()

                    if viewModel.introVisible {
                        WelcomeScreenView {
                            viewModel.handleIntroFinish()
                        }
                        .ignoresSafeArea()
                    } else if viewModel.locked {
                        AppUnlockView()
                    } else if viewModel.coverVisible {
                        CoverView()
                    }
                }
            case .passcodeNotSet:
                NoPasscodeView(mode: .noPasscode)
            case .unknown:
                NoPasscodeView(mode: .cannotCheckPasscode)
            }
        }
        .preferredColorScheme(viewModel.themeMode.colorScheme)
    }
}
