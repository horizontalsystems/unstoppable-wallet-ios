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
