import SwiftUI

struct SecuritySettingsView: View {
    @ObservedObject var viewModel: SecuritySettingsViewModel
    @StateObject var unlockViewModifierModel = UnlockViewModifierModel()

    @State var createPasscodeReason: CreatePasscodeModule.CreatePasscodeReason?

    @State var biometryEnabledTypePresented = false
    @State var editPasscodePresented = false
    @State var createDuressPasscodePresented = false
    @State var editDuressPasscodePresented = false

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin32) {
                ListSection {
                    if viewModel.isPasscodeSet {
                        ClickableRow(action: {
                            unlockViewModifierModel.handle {
                                editPasscodePresented = true
                            }
                        }) {
                            Image("dialpad_alt_2_24").themeIcon(color: .themeJacob)
                            Text("settings_security.edit_passcode".localized).themeBody(color: .themeJacob)
                        }

                        ClickableRow(action: {
                            unlockViewModifierModel.handle {
                                viewModel.removePasscode()
                            }
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
                        NavigationRow(spacing: .margin8, destination: {
                            AutoLockView(period: $viewModel.autoLockPeriod)
                        }) {
                            HStack(spacing: .margin16) {
                                Image("lock_24").themeIcon()
                                Text("settings_security.auto_lock".localized).textBody()
                            }

                            Spacer()

                            Text(viewModel.autoLockPeriod.title).textSubhead1()
                            Image.disclosureIcon
                        }
                    }
                }

                if let biometryType = viewModel.biometryType {
                    ListSection {
                        ClickableRow(spacing: .margin8, action: {
                            biometryEnabledTypePresented = true
                        }) {
                            HStack(spacing: .margin16) {
                                Image(biometryType.iconName)
                                Text(biometryType.title).textBody()
                            }

                            Spacer()

                            Text(viewModel.biometryEnabledType.title).textSubhead1(color: viewModel.biometryEnabledType.isEnabled ? .themeLeah : .themeGray)
                            Image("arrow_small_down_20").themeIcon()
                        }
                        .onChange(of: viewModel.biometryEnabledType) { type in
                            if !viewModel.isPasscodeSet, type.isEnabled {
                                createPasscodeReason = .biometry(enabledType: type, type: biometryType)
                            }
                        }
                    }
                    .alert(
                        isPresented: $biometryEnabledTypePresented,
                        title: biometryType.title,
                        viewItems: BiometryManager.BiometryEnabledType.allCases.map {
                            .init(text: $0.title, description: $0.description, selected: $0 == viewModel.biometryEnabledType)
                        },
                        onTap: { index in
                            let all = BiometryManager.BiometryEnabledType.allCases
                            guard let index, index < all.count else {
                                return
                            }
                            viewModel.biometryEnabledType = all[index]
                        }
                    )
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
                    PremiumListSectionHeader()

                    ListSection {
                        if viewModel.isDuressPasscodeSet {
                            ClickableRow(action: {
                                guard viewModel.premiumEnabled else {
                                    Coordinator.shared.presentPurchases()
                                    stat(page: .security, event: .openPremium(from: .duressMode))
                                    return
                                }
                                unlockViewModifierModel.handle {
                                    editDuressPasscodePresented = true
                                }

                            }) {
                                Image("switch_wallet_24").themeIcon(color: .themeJacob)
                                Text("settings_security.edit_duress_passcode".localized).themeBody()
                            }

                            ClickableRow(action: {
                                unlockViewModifierModel.handle {
                                    viewModel.removeDuressPasscode()
                                }
                            }) {
                                Image("trash_24").themeIcon(color: .themeLucian)
                                Text("settings_security.disable_duress_mode".localized).themeBody(color: .themeLucian)
                            }
                        } else {
                            ClickableRow(action: {
                                guard viewModel.premiumEnabled else {
                                    Coordinator.shared.presentPurchases()
                                    stat(page: .security, event: .openPremium(from: .duressMode))
                                    return
                                }

                                if viewModel.isPasscodeSet {
                                    unlockViewModifierModel.handle {
                                        createDuressPasscodePresented = true
                                    }
                                } else {
                                    createPasscodeReason = .duress
                                }
                            }) {
                                Image("switch_wallet_24").themeIcon(color: .themeJacob)
                                Text("settings_security.enable_duress_mode".localized).themeBody()
                            }
                        }
                    }
                    .modifier(ColoredBorder())

                    ListSectionFooter(text: "settings_security.duress_mode.description".localized)
                }
            }
            .sheet(item: $createPasscodeReason) { reason in
                ThemeNavigationStack {
                    CreatePasscodeModule.createPasscodeView(
                        reason: reason,
                        showParentSheet: Binding(get: { createPasscodeReason != nil }, set: { if !$0 { createPasscodeReason = nil } }),
                        onCreate: {
                            switch reason {
                            case let .biometry(enabledType, _):
                                viewModel.set(biometryEnabledType: enabledType)
                            case .duress:
                                DispatchQueue.main.async {
                                    createDuressPasscodePresented = true
                                }
                            default: ()
                            }
                        },
                        onCancel: {
                            switch reason {
                            case .biometry: viewModel.biometryEnabledType = .off
                            default: ()
                            }
                        }
                    )
                }
                .interactiveDismiss(canDismissSheet: false)
            }
            .sheet(isPresented: $editPasscodePresented) {
                ThemeNavigationStack { EditPasscodeModule.editPasscodeView(showParentSheet: $editPasscodePresented) }
            }
            .sheet(isPresented: $createDuressPasscodePresented) {
                ThemeNavigationStack { DuressModeModule.view(showParentSheet: $createDuressPasscodePresented) }
            }
            .sheet(isPresented: $editDuressPasscodePresented) {
                ThemeNavigationStack { EditPasscodeModule.editDuressPasscodeView(showParentSheet: $editDuressPasscodePresented) }
            }
            .modifier(UnlockViewModifier(viewModel: unlockViewModifierModel))
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("settings_security.title".localized)
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
