import SwiftUI

struct SecuritySettingsView: View {
    @ObservedObject var viewModel: SecuritySettingsViewModel

    @State var createPasscodeReason: CreatePasscodeModule.CreatePasscodeReason?
    @State var unlockReason: UnlockReason?

    @State var biometryEnabledTypePresented = false
    @State var editPasscodePresented = false
    @State var createDuressPasscodePresented = false
    @State var editDuressPasscodePresented = false
    @State var subscriptionPresented = false

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
                            .toggleStyle(SwitchToggleStyle(tint: .themeOrange))
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
                                    subscriptionPresented = true
                                    return
                                }
                                unlockReason = .changeDuressPasscode
                            }) {
                                Image("switch_wallet_24").themeIcon(color: .themeJacob)
                                Text("settings_security.edit_duress_passcode".localized).themeBody()
                            }

                            ClickableRow(action: {
                                unlockReason = .disableDuressMode
                            }) {
                                Image("trash_24").themeIcon(color: .themeLucian)
                                Text("settings_security.disable_duress_mode".localized).themeBody(color: .themeLucian)
                            }
                        } else {
                            ClickableRow(action: {
                                guard viewModel.premiumEnabled else {
                                    subscriptionPresented = true
                                    return
                                }

                                if viewModel.isPasscodeSet {
                                    unlockReason = .enableDuressMode
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
                ThemeNavigationView {
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
            .sheet(isPresented: $subscriptionPresented) {
                PurchasesView()
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
