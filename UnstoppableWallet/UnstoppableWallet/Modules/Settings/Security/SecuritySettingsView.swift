import SwiftUI

struct SecuritySettingsView: View {
    @StateObject var viewModel = SecuritySettingsViewModel()

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin32) {
                ListSection {
                    if viewModel.isPasscodeSet {
                        ClickableRow(action: {
                            Coordinator.shared.presentAfterUnlock { isPresented in
                                ThemeNavigationStack { EditPasscodeModule.editPasscodeView(showParentSheet: isPresented) }
                            }
                        }) {
                            Image("dialpad_alt_2_24").themeIcon(color: .themeJacob)
                            Text("settings_security.edit_passcode".localized).themeBody(color: .themeJacob)
                        }

                        ClickableRow(action: {
                            Coordinator.shared.performAfterUnlock {
                                viewModel.removePasscode()
                            }
                        }) {
                            Image("trash_24").themeIcon(color: .themeLucian)
                            Text("settings_security.disable_passcode".localized).themeBody(color: .themeLucian)
                        }
                    } else {
                        ClickableRow(action: {
                            presentCreatePasscode(reason: .regular)
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
                            Coordinator.shared.present(type: .alert) { isPresented in
                                OptionAlertView(
                                    title: biometryType.title,
                                    viewItems: BiometryManager.BiometryEnabledType.allCases.map {
                                        .init(text: $0.title, description: $0.description, selected: $0 == viewModel.biometryEnabledType)
                                    },
                                    onSelect: { index in
                                        viewModel.biometryEnabledType = BiometryManager.BiometryEnabledType.allCases[index]
                                    },
                                    isPresented: isPresented
                                )
                            }
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
                                presentCreatePasscode(reason: .biometry(enabledType: type, type: biometryType))
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

                premiumSection()
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("settings_security.title".localized)
    }

    private func presentCreatePasscode(reason: CreatePasscodeModule.CreatePasscodeReason) {
        Coordinator.shared.present { isPresented in
            ThemeNavigationStack {
                CreatePasscodeModule.createPasscodeView(
                    reason: reason,
                    showParentSheet: isPresented,
                    onCreate: {
                        switch reason {
                        case let .biometry(enabledType, _):
                            viewModel.set(biometryEnabledType: enabledType)
                        case .duress:
                            presentCreateDuressPasscode()
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
    }

    private func presentCreateDuressPasscode() {
        Coordinator.shared.present { isPresented in
            ThemeNavigationStack { DuressModeModule.view(showParentSheet: isPresented) }
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

    @ViewBuilder
    private func premiumSection() -> some View {
        VStack(spacing: 0) {
            SectionHeader(image: Image.defenseIcon, text: "purchases.defense_system".localized, horizontalInsets: .margin16)

            ListSection {
                toggledRow(title: "purchases.secure_send".localized, subtitle: "purchases.secure_send.description".localized, isOn: viewModel.isEnabled(.secureSend))
                    .tapIntercept(active: true) {
                        Coordinator.shared.performAfterPurchase(premiumFeature: .secureSend, page: .security, trigger: .getPremium) {
                            presentSecureSendSheet()
                        }
                    }

                toggledRow(title: "purchases.scam_protection".localized, subtitle: "purchases.scam_protection.description".localized, isOn: binding(feature: .scamProtection))
                    .tapIntercept(active: !viewModel.premiumEnabled) {
                        Coordinator.shared.performAfterPurchase(premiumFeature: .scamProtection, page: .security, trigger: .getPremium) {
                            viewModel.set(.scamProtection, enabled: !viewModel.isEnabled(.scamProtection))
                        }
                    }

                toggledRow(title: "purchases.swap_protection".localized, subtitle: "purchases.swap_protection.description".localized, isOn: binding(feature: .swapProtection))
                    .tapIntercept(active: !viewModel.premiumEnabled) {
                        Coordinator.shared.performAfterPurchase(premiumFeature: .swapProtection, page: .security, trigger: .getPremium) {
                            viewModel.set(.swapProtection, enabled: !viewModel.isEnabled(.swapProtection))
                        }
                    }

                robberyRow()
            }
            .themeListStyle(.borderedPremium)
        }
    }

    private func presentSecureSendSheet() {
        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            SecureSendBottomSheetView(isPresented: isPresented)
        }
    }

    private func binding(feature: PremiumFeature) -> Binding<Bool> {
        Binding(
            get: { viewModel.isEnabled(feature) },
            set: { viewModel.set(feature, enabled: $0) }
        )
    }

    @ViewBuilder
    private func toggledRow(title: CustomStringConvertible, subtitle: CustomStringConvertible, isOn: Binding<Bool>) -> some View {
        Cell(
            middle: {
                MultiText(title: title, subtitle: subtitle)
            },
            right: {
                ThemeToggle(isOn: isOn)
            }
        )
    }

    @ViewBuilder
    private func toggledRow(title: CustomStringConvertible, subtitle: CustomStringConvertible, isOn: Bool) -> some View {
        Cell(
            middle: {
                MultiText(title: title, subtitle: subtitle)
            },
            right: {
                ThemeToggle(isOn: .constant(isOn))
            }
        )
    }

    @ViewBuilder
    private func robberyRow() -> some View {
        Cell(
            middle: {
                MultiText(title: "purchases.robbery_protection".localized, subtitle: "purchases.robbery_protection.description".localized)
            },
            right: {
                if viewModel.isDuressPasscodeSet {
                    HStack(spacing: .margin12) {
                        Button {
                            Coordinator.shared.performAfterPurchase(premiumFeature: .robberyProtection, page: .security, trigger: .robberyProtection) {
                                Coordinator.shared.presentAfterUnlock { isPresented in
                                    ThemeNavigationStack { EditPasscodeModule.editDuressPasscodeView(showParentSheet: isPresented) }
                                }
                            }
                        } label: {
                            Image("pen")
                        }
                        .buttonStyle(SecondaryCircleButtonStyle())

                        Button {
                            Coordinator.shared.performAfterUnlock {
                                viewModel.removeDuressPasscode()
                            }
                        } label: {
                            Image("trash")
                        }
                        .buttonStyle(SecondaryCircleButtonStyle())
                    }
                } else {
                    Button {
                        Coordinator.shared.performAfterPurchase(premiumFeature: .robberyProtection, page: .security, trigger: .robberyProtection) {
                            if viewModel.isPasscodeSet {
                                Coordinator.shared.performAfterUnlock {
                                    presentCreateDuressPasscode()
                                }
                            } else {
                                presentCreatePasscode(reason: .duress)
                            }
                        }
                    } label: {
                        Text("button.add".localized)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
        )
    }
}
