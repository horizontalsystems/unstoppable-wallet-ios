import SwiftUI

struct SecuritySettingsView: View {
    @StateObject var viewModel = SecuritySettingsViewModel()

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: 0) {
                VStack(spacing: .margin16) {
                    ListSection {
                        passcodeRow()

                        if let biometryType = viewModel.biometryType {
                            Cell(
                                middle: {
                                    MultiText(title: biometryType.title)
                                },
                                right: {
                                    DropdownButton(text: viewModel.biometryEnabledType.title, mode: .transparent) {
                                        Coordinator.shared.present(type: .alert) { isPresented in
                                            OptionAlertView(
                                                title: biometryType.title,
                                                viewItems: BiometryManager.BiometryEnabledType.allCases.map {
                                                    .init(text: $0.title, selected: $0 == viewModel.biometryEnabledType)
                                                },
                                                onSelect: { index in
                                                    viewModel.biometryEnabledType = BiometryManager.BiometryEnabledType.allCases[index]
                                                },
                                                isPresented: isPresented
                                            )
                                        }
                                    }
                                    .accessibilityIdentifier(TestTags.securityBiometrics)
                                }
                            )
                            .onChange(of: viewModel.biometryEnabledType) { type in
                                if !viewModel.isPasscodeSet, type.isEnabled {
                                    presentCreatePasscode(reason: .biometry(enabledType: type, type: biometryType))
                                }
                            }
                        }

                        if viewModel.isPasscodeSet {
                            Cell(
                                middle: {
                                    MultiText(title: "settings_security.auto_lock".localized, subtitle: "settings_security.auto_lock.description".localized)
                                },
                                right: {
                                    DropdownButton(text: viewModel.autoLockPeriod.title, mode: .transparent) {
                                        Coordinator.shared.present(type: .alert) { isPresented in
                                            OptionAlertView(
                                                title: "settings_security.auto_lock".localized,
                                                viewItems: AutoLockPeriod.allCases.map { .init(text: $0.title, selected: viewModel.autoLockPeriod == $0, identifier: TestTags.autolockInterval($0.identifierRaw)) },
                                                onSelect: { index in
                                                    viewModel.autoLockPeriod = AutoLockPeriod.allCases[index]
                                                },
                                                isPresented: isPresented
                                            )
                                        }
                                    }
                                    .accessibilityIdentifier(TestTags.securityAutolock)
                                }
                            )
                        }
                    }

                    ListSection {
                        toggledRow(title: "settings_security.balance_auto_hide".localized, subtitle: "settings_security.balance_auto_hide.description".localized, isOn: $viewModel.balanceAutoHide)

                        toggledRow(title: "transaction_filter.hide_suspicious_txs".localized, subtitle: "transaction_filter.hide_suspicious_txs.description".localized, isOn: $viewModel.spamFilterEnabled)
                    }
                }

                defenseSection()
            }
            .padding(EdgeInsets(top: .margin16, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("settings.security".localized)
    }

    private func passcodeRow() -> some View {
        Cell(
            middle: {
                MultiText(title: "settings_security.passcode".localized)
            },
            right: {
                HStack(spacing: .margin12) {
                    if !viewModel.isPasscodeSet {
                        ThemeImage("warning_filled", size: .iconSize20, colorStyle: .red)
                    }

                    interceptedToggle(
                        isOn: viewModel.isPasscodeSet,
                        title: "settings_security.passcode".localized,
                        identifier: TestTags.securityPasscode
                    ) {
                        togglePasscode()
                    }
                }
            }
        )
    }

    private func togglePasscode() {
        if viewModel.isPasscodeSet {
            Coordinator.shared.performAfterUnlock(biometryAllowed: false) {
                viewModel.removePasscode()
            }
        } else {
            presentCreatePasscode(reason: .regular)
        }
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

    private func defenseSection() -> some View {
        VStack(spacing: 0) {
            SectionHeader(image: Image.defenseIcon, text: "purchases.defense_system".localized, horizontalInsets: .margin16)
                .padding(.top, .margin8)

            ListSection {
                Cell(
                    middle: {
                        MultiText(title: "purchases.secure_send".localized, subtitle: "purchases.secure_send.description".localized)
                    },
                    right: {
                        interceptedToggle(
                            isOn: viewModel.secureSendEnabled,
                            title: "purchases.secure_send".localized,
                            identifier: TestTags.securitySecureSend
                        ) {
                            presentSecureSendSheet()
                        }
                    }
                )

                toggledRow(
                    title: "purchases.scam_protection".localized,
                    subtitle: "purchases.scam_protection.description".localized,
                    isOn: Binding(get: { viewModel.scamProtectionEnabled }, set: { viewModel.setScamProtection(enabled: $0) }),
                    identifier: TestTags.securityScamProtection
                )

                if viewModel.swapEnabled {
                    toggledRow(
                        title: "purchases.swap_protection".localized,
                        subtitle: "purchases.swap_protection.description".localized,
                        isOn: Binding(get: { viewModel.swapProtectionEnabled }, set: { viewModel.setSwapProtection(enabled: $0) }),
                        identifier: TestTags.securitySwapProtection
                    )
                }

                robberyRow()
            }
        }
    }

    private func presentSecureSendSheet() {
        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            SecureSendBottomSheetView(isPresented: isPresented)
        }
    }

    private func presentDisableRobberyProtectionSheet() {
        let passcodeLevel = viewModel.currentPasscodeLevel

        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            BottomSheetView(
                items: [
                    .title(icon: ThemeImage.trash, title: "settings_security.disable_robbery_protection.title".localized),
                    .text(text: "settings_security.disable_robbery_protection.description".localized),
                    .buttonGroup(.init(buttons: [
                        .init(style: .secondary, title: "settings_security.disable_robbery_protection.button".localized, identifier: TestTags.robberyProtectionDisableConfirm) {
                            isPresented.wrappedValue = false

                            guard viewModel.currentPasscodeLevel == passcodeLevel else {
                                return
                            }

                            viewModel.removeDuressPasscode()
                        },
                    ])),
                ]
            )
            // The lock screen is a separate window, so the sheet would survive a lock and
            // could be confirmed at another passcode level: close it as soon as the app locks.
            .onReceive(Core.shared.lockManager.$isLocked) { isLocked in
                if isLocked {
                    isPresented.wrappedValue = false
                }
            }
        }
    }

    private func interceptedToggle(isOn: Bool, title: String, identifier: String, action: @escaping () -> Void) -> some View {
        ThemeToggle(isOn: .constant(isOn))
            .tapIntercept(active: true, action: action)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
            .accessibilityValue(isOn ? "biometry.on".localized : "biometry.off".localized)
            .accessibilityAddTraits(.isToggle)
            .accessibilityAction { action() }
            .accessibilityIdentifier(identifier)
    }

    private func toggledRow(title: CustomStringConvertible, subtitle: CustomStringConvertible, isOn: Binding<Bool>, identifier: String? = nil) -> some View {
        Cell(
            middle: {
                MultiText(title: title, subtitle: subtitle)
            },
            right: {
                ThemeToggle(isOn: isOn)
                    .withIdentifier(identifier)
            }
        )
    }

    private func robberyRow() -> some View {
        Cell(
            middle: {
                MultiText(title: "purchases.robbery_protection".localized, subtitle: "purchases.robbery_protection.description".localized)
            },
            right: {
                if viewModel.isDuressPasscodeSet {
                    HStack(spacing: .margin12) {
                        IconButton(icon: "pen", style: .secondary, size: .small) {
                            Coordinator.shared.presentAfterUnlock { isPresented in
                                ThemeNavigationStack { EditPasscodeModule.editDuressPasscodeView(showParentSheet: isPresented) }
                            }
                        }
                        .accessibilityIdentifier(TestTags.securityRobberyProtectionEdit)

                        IconButton(icon: "trash", style: .secondary, size: .small) {
                            Coordinator.shared.performAfterUnlock {
                                presentDisableRobberyProtectionSheet()
                            }
                        }
                        .accessibilityIdentifier(TestTags.securityRobberyProtectionDisable)
                    }
                } else {
                    ThemeButton(text: "button.add".localized, style: .secondary, size: .small) {
                        if viewModel.isPasscodeSet {
                            Coordinator.shared.performAfterUnlock {
                                presentCreateDuressPasscode()
                            }
                        } else {
                            presentCreatePasscode(reason: .duress)
                        }
                    }
                    .accessibilityIdentifier(TestTags.securityRobberyProtectionAdd)
                }
            }
        )
    }
}
