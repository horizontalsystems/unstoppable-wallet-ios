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

                if viewModel.isPasscodeSet {
                    ListSection {
                        NavigationRow(destination: {
                            AutoLockView(period: $viewModel.autoLockPeriod)
                        }) {
                            Image("lock_24").themeIcon()
                            Text("settings_security.auto_lock".localized).themeBody()
                            Text(viewModel.autoLockPeriod.title).themeSubhead1(alignment: .trailing).padding(.trailing, -.margin8)
                            Image.disclosureIcon
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
                            .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
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
                            .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
                        }
                    }

                    ListSectionFooter(text: "settings_security.balance_auto_hide.description".localized)
                }

                VStack(spacing: 0) {
                    ListSection {
                        if viewModel.isDuressPasscodeSet {
                            ClickableRow(action: {
                                unlockReason = .changeDuressPasscode
                            }) {
                                Image("switch_wallet_24").themeIcon(color: .themeJacob)
                                Text("settings_security.edit_duress_passcode".localized).themeBody(color: .themeJacob)
                            }

                            ClickableRow(action: {
                                unlockReason = .disableDuressMode
                            }) {
                                Image("trash_24").themeIcon(color: .themeLucian)
                                Text("settings_security.disable_duress_mode".localized).themeBody(color: .themeLucian)
                            }
                        } else {
                            ClickableRow(action: {
                                if viewModel.isPasscodeSet {
                                    unlockReason = .enableDuressMode
                                } else {
                                    createPasscodeReason = .duress
                                }
                            }) {
                                Image("switch_wallet_24").themeIcon(color: .themeJacob)
                                Text("settings_security.enable_duress_mode".localized).themeBody(color: .themeJacob)
                            }
                        }
                    }

                    ListSectionFooter(text: "settings_security.duress_mode.description".localized)
                }
            }
            .sheet(item: $createPasscodeReason) { reason in
                ThemeNavigationView {
                    CreatePasscodeModule.createPasscodeView(
                        reason: reason,
                        showParentSheet: Binding(get: { createPasscodeReason != nil }, set: { if !$0 { createPasscodeReason = nil } }),
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
                .interactiveDismiss(canDismissSheet: false)
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
                ThemeNavigationView { EditPasscodeModule.editPasscodeView(showParentSheet: $editPasscodePresented) }
            }
            .sheet(isPresented: $createDuressPasscodePresented) {
                ThemeNavigationView { DuressModeModule.view(showParentSheet: $createDuressPasscodePresented) }
            }
            .sheet(isPresented: $editDuressPasscodePresented) {
                ThemeNavigationView { EditPasscodeModule.editDuressPasscodeView(showParentSheet: $editDuressPasscodePresented) }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("settings_security.title".localized)
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

    private struct AutoLockView: View {
        @Binding var period: AutoLockPeriod
        @Environment(\.presentationMode) private var presentationMode

        var body: some View {
            ScrollableThemeView {
                ListSection {
                    ForEach(AutoLockPeriod.allCases, id: \.self) { period in
                        ClickableRow(action: {
                            self.period = period
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text(period.title).themeBody()

                            if self.period == period {
                                Image.checkIcon
                            }
                        }
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            }
            .navigationTitle("settings_security.auto_lock".localized)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
