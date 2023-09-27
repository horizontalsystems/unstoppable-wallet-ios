import SwiftUI

struct SecuritySettingsView: View {
    @ObservedObject var viewModel: SecuritySettingsViewModel

    @State var createPasscodeReason: CreatePasscodeModule.CreatePasscodeReason?
    @State var unlockReason: UnlockReason?

    @State var editPasscodePresented = false
    @State var createDuressPasscodePresented = false
    @State var editDuressPasscodePresented = false

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin32) {
                ListSection {
                    if viewModel.isPasscodeSet {
                        ClickableRow(action: {
                            unlockReason = .changePasscode
                        }) {
                            Image("dialpad_alt_2_24").themeIcon(color: .themeJacob)
                            Text("settings_security.edit_passcode".localized).themeBody(color: .themeJacob)
                        }

                        ClickableRow(action: {
                            unlockReason = .disablePasscode
                        }) {
                            Image("trash_24").themeIcon(color: .themeLucian)
                            Text("settings_security.disable_passcode".localized).themeBody(color: .themeLucian)
                        }
                    } else {
                        ClickableRow(action: {
                            createPasscodeReason = .regular
                        }) {
                            Image("dialpad_alt_2_24").themeIcon(color: .themeJacob)
                            Text("settings_security.enable_passcode".localized).themeBody(color: .themeJacob)
                            Image("warning_2_20").themeIcon(color: .themeLucian)
                        }
                    }
                }

                if let biometryType = viewModel.biometryType {
                    ListSection {
                        ListRow {
                            Image(biometryType.iconName)
                            Toggle(isOn: $viewModel.isBiometryToggleOn) {
                                Text(biometryType.title).themeBody()
                            }
                            .onChange(of: viewModel.isBiometryToggleOn) { isOn in
                                if !viewModel.isPasscodeSet, isOn {
                                    createPasscodeReason = .biometry(type: biometryType)
                                }
                            }
                        }
                    }
                }

                VStack(spacing: 0) {
                    ListSection {
                        ListRow {
                            Image("eye_off_24").themeIcon()
                            Toggle(isOn: $viewModel.balanceAutoHide) {
                                Text("settings_security.balance_auto_hide".localized).themeBody()
                            }
                        }
                    }

                    ListSectionFooter(text: "settings_security.balance_auto_hide.description".localized)
                }
            }
            .sheet(item: $createPasscodeReason) { reason in
                CreatePasscodeModule.createPasscodeView(
                    reason: reason,
                    onCreate: {
                        switch reason {
                        case .biometry:
                            viewModel.set(biometryEnabled: true)
                        case .duress:
                            DispatchQueue.main.async {
                                createDuressPasscodePresented = true
                            }
                        default: ()
                        }
                    },
                    onCancel: {
                        switch reason {
                        case .biometry: viewModel.isBiometryToggleOn = false
                        default: ()
                        }
                    }
                )
            }
            .sheet(item: $unlockReason) { reason in
                ThemeNavigationView {
                    UnlockModule.moduleUnlockView {
                        switch reason {
                        case .changePasscode:
                            DispatchQueue.main.async {
                                editPasscodePresented = true
                            }
                        case .disablePasscode:
                            viewModel.removePasscode()
                        case .enableDuressMode:
                            DispatchQueue.main.async {
                                createDuressPasscodePresented = true
                            }
                        case .changeDuressPasscode:
                            DispatchQueue.main.async {
                                editDuressPasscodePresented = true
                            }
                        case .disableDuressMode:
                            viewModel.removeDuressPasscode()
                        }
                    }
                }
            }
            .sheet(isPresented: $editPasscodePresented) {
                EditPasscodeModule.editPasscodeView()
            }
            .sheet(isPresented: $createDuressPasscodePresented) {
                CreatePasscodeModule.createDuressPasscodeView()
            }
            .sheet(isPresented: $editDuressPasscodePresented) {
                EditPasscodeModule.editDuressPasscodeView()
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
    }

    enum UnlockReason: Identifiable {
        case changePasscode
        case disablePasscode
        case enableDuressMode
        case changeDuressPasscode
        case disableDuressMode

        var id: Self {
            self
        }
    }
}
