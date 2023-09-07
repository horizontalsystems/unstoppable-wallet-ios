import PinKit
import SwiftUI

struct SecuritySettingsView: View {
    @ObservedObject var viewModel: SecuritySettingsViewModel
    @State var editPasscodePresented: Bool = false

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin32) {
                ListSection {
                    ListRow {
                        Image("dialpad_alt_2_24")
                        Text("settings_security.passcode".localized).themeBody()
                        Spacer()

                        if !viewModel.passcodeEnabled {
                            Image("warning_2_20")
                                .renderingMode(.template)
                                .foregroundColor(.themeLucian)
                        }

                        Toggle(isOn: $viewModel.passcodeSwitchOn) {}
                            .labelsHidden()
                    }
                    .sheet(isPresented: $viewModel.setPasscodePresented, onDismiss: { viewModel.cancelSetPasscode() }) {
                        SetPinView(
                            cancelAction: { viewModel.cancelSetPasscode() }
                        ).edgesIgnoringSafeArea(.all)
                    }
                    .sheet(isPresented: $viewModel.unlockPasscodePresented, onDismiss: { viewModel.cancelUnlock() }) {
                        UnlockPinView(
                            unlockAction: { viewModel.onUnlock() },
                            cancelAction: { viewModel.cancelUnlock() }
                        ).edgesIgnoringSafeArea(.all)
                    }

                    if viewModel.passcodeEnabled {
                        ClickableRow(action: { editPasscodePresented = true }) {
                            Text("settings_security.change_pin".localized).themeBody()
                            Image.disclosureIcon
                        }
                        .sheet(isPresented: $editPasscodePresented) {
                            EditPinView().edgesIgnoringSafeArea(.all)
                        }
                    }
                }

                if viewModel.passcodeEnabled && viewModel.biometryAvailable {
                    ListSection {
                        ListRow {
                            Image(viewModel.biometryIconName)
                            Toggle(isOn: $viewModel.biometryEnabled) {
                                Text(viewModel.biometryTitle).themeBody()
                            }
                        }
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
    }
}

struct SetPinView: UIViewControllerRepresentable, ISetPinDelegate {
    typealias UIViewControllerType = UIViewController

    let cancelAction: () -> ()

    func makeUIViewController(context: Context) -> UIViewController {
        App.shared.pinKit.setPinModule(delegate: self)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func didCancelSetPin() {
        cancelAction()
    }
}

struct EditPinView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        return App.shared.pinKit.editPinModule
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

struct UnlockPinView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let unlockAction: () -> ()
    let cancelAction: () -> ()

    func makeUIViewController(context: Context) -> UIViewController {
        return App.shared.pinKit.unlockPinModule(
            biometryUnlockMode: .disabled,
            insets: .zero,
            cancellable: true,
            autoDismiss: true,
            onUnlock: unlockAction,
            onCancelUnlock: cancelAction
        )
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
