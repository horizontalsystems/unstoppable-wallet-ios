import SwiftUI

struct ManageAccountView: View {
    @StateObject private var viewModel: ManageAccountViewModel
    @StateObject private var accountWarningViewModel: AccountWarningViewModel

    @Binding var isPresented: Bool

    @State private var recoveryPhrasePresented = false
    @FocusState private var isNameFocused: Bool

    init(account: Account, isPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: ManageAccountViewModel(account: account))
        _accountWarningViewModel = StateObject(wrappedValue: AccountWarningViewModel(predefinedAccount: account, ignoreType: .auto))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack {
            ScrollableThemeView {
                VStack(spacing: .margin24) {
                    VStack(spacing: 0) {
                        ListSectionHeader(text: "manage_account.name".localized)

                        InputTextRow {
                            InputTextView(
                                placeholder: viewModel.account.name,
                                text: $viewModel.name
                            )
                            .autocapitalization(.words)
                            .autocorrectionDisabled()
                            .focused($isNameFocused)
                        }
                    }

                    AccountWarningView(viewModel: accountWarningViewModel)

                    if viewModel.account.backedUp || viewModel.isCloudBackedUp {
                        ListSection {
                            if viewModel.recoveryPhraseVisible {
                                ClickableRow(action: {
                                    Coordinator.shared.performAfterUnlock {
                                        recoveryPhrasePresented = true
                                    }
                                }) {
                                    Image("paper_contract_24").themeIcon()
                                    Text("manage_account.recovery_phrase".localized).themeBody()
                                    Image.disclosureIcon
                                }
                            }

                            if viewModel.privateKeysVisible {
                                NavigationRow(destination: {
                                    PrivateKeysView(account: viewModel.account)
                                        .navigationTitle("private_keys.title".localized)
                                        .ignoresSafeArea()
                                        .onFirstAppear {
                                            stat(page: .manageWallet, event: .open(page: .privateKeys))
                                        }
                                }) {
                                    Image("key_24").themeIcon()
                                    Text("manage_account.private_keys".localized).themeBody()
                                    Image.disclosureIcon
                                }
                            }

                            if viewModel.publicKeysVisible {
                                NavigationRow(destination: {
                                    PublicKeysView(account: viewModel.account)
                                        .navigationTitle("public_keys.title".localized)
                                        .ignoresSafeArea()
                                        .onFirstAppear {
                                            stat(page: .manageWallet, event: .open(page: .publicKeys))
                                        }
                                }) {
                                    Image("binocule_24").themeIcon()
                                    Text("manage_account.public_keys".localized).themeBody()
                                    Image.disclosureIcon
                                }
                            }
                        }
                    }

                    ListSection(
                        footer: viewModel.account.backedUp || viewModel.isCloudBackedUp ? "manage_account.backup.has_backup_description".localized : "manage_account.backup.no_backup_yet_description".localized
                    ) {
                        if viewModel.account.canBeBackedUp {
                            ClickableRow {
                                Coordinator.shared.performAfterUnlock {
                                    presentBackup(reason: .manual)
                                }
                            } content: {
                                Image("edit_24").themeIcon(color: .themeJacob)
                                Text("manage_account.backup_recovery_phrase".localized).themeBody(color: .themeJacob)

                                if viewModel.account.backedUp {
                                    Image("check_1_20").themeIcon(color: .themeRemus)
                                } else {
                                    Image("warning_2_24").themeIcon(color: .themeLucian)
                                }
                            }
                        }

                        if !viewModel.account.watchAccount {
                            if viewModel.isCloudBackedUp {
                                ClickableRow {
                                    if viewModel.account.backedUp {
                                        Coordinator.shared.present(type: .bottomSheet) { isPresented in
                                            confirmDeleteCloudBackupView(isPresented: isPresented)
                                        }
                                    } else {
                                        Coordinator.shared.present(type: .bottomSheet) { isPresented in
                                            confirmDeleteCloudBackupAfterManualBackupView(isPresented: isPresented)
                                        }
                                    }
                                } content: {
                                    Image("no_internet_24").themeIcon(color: .themeLucian)
                                    Text("manage_account.cloud_delete_backup_recovery_phrase".localized).themeBody(color: .themeLucian)
                                }
                            } else {
                                ClickableRow {
                                    Coordinator.shared.presentAfterUnlock { _ in
                                        ICloudBackupTermsView(account: viewModel.account)
                                            .ignoresSafeArea()
                                    } onPresent: {
                                        stat(page: .manageWallet, event: .open(page: .cloudBackup))
                                    }
                                } content: {
                                    Image("icloud_24").themeIcon(color: .themeJacob)
                                    Text("manage_account.cloud_backup_recovery_phrase".localized).themeBody(color: .themeJacob)

                                    if !viewModel.account.backedUp {
                                        Image("warning_2_24").themeIcon(color: .themeLucian)
                                    }
                                }
                            }
                        }
                    }

                    ListSection {
                        ClickableRow(action: {
                            if viewModel.account.watchAccount {
                                Coordinator.shared.present(type: .bottomSheet) { isPresented in
                                    confirmUnlinkWatchView(isPresented: isPresented)
                                }
                            } else {
                                Coordinator.shared.present(type: .bottomSheet) { isPresented in
                                    UnlinkView(isPresented: isPresented) {
                                        unlink()
                                    }
                                }
                            }
                        }) {
                            Image("trash_24").themeIcon(color: .themeLucian)
                            Text("manage_account.unlink".localized).themeBody(color: .themeLucian)
                        }
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            }
            .onTapGesture {
                isNameFocused = false
            }
            .navigationDestination(isPresented: $recoveryPhrasePresented) {
                RecoveryPhraseView(account: viewModel.account)
                    .navigationTitle("recovery_phrase.title".localized)
                    .ignoresSafeArea()
                    .onFirstAppear {
                        stat(page: .manageWallet, event: .open(page: .recoveryPhrase))
                    }
            }
            .navigationTitle(viewModel.account.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button.close".localized) {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("button.save".localized) {
                        viewModel.save()
                        isPresented = false
                        stat(page: .manageWallet, event: .edit(entity: .walletName))
                    }
                    .disabled(viewModel.name.isEmpty || viewModel.account.name == viewModel.name)
                }
            }
        }
    }

    @ViewBuilder private func confirmUnlinkWatchView(isPresented: Binding<Bool>) -> some View {
        BottomSheetView(
            icon: .warning,
            title: "settings_manage_keys.delete.title".localized,
            items: [
                .highlightedDescription(text: "settings_manage_keys.delete.confirmation_watch".localized, style: .warning),
            ],
            buttons: [
                .init(style: .red, title: "settings_manage_keys.delete.confirmation_watch.button".localized) {
                    unlink()
                },
            ],
            isPresented: isPresented
        )
    }

    @ViewBuilder private func confirmDeleteCloudBackupView(isPresented: Binding<Bool>) -> some View {
        BottomSheetView(
            icon: .trash,
            title: "manage_account.cloud_delete_backup_recovery_phrase".localized,
            items: [
                .highlightedDescription(text: "manage_account.cloud_delete_backup_recovery_phrase.description".localized, style: .warning),
            ],
            buttons: [
                .init(style: .red, title: "button.delete".localized) {
                    isPresented.wrappedValue = false
                    deleteCloudBackup()
                },
                .init(style: .transparent, title: "button.cancel".localized) {
                    isPresented.wrappedValue = false
                },
            ],
            isPresented: isPresented
        )
    }

    @ViewBuilder private func confirmDeleteCloudBackupAfterManualBackupView(isPresented: Binding<Bool>) -> some View {
        BottomSheetView(
            icon: .warning,
            title: "manage_account.manual_backup_required".localized,
            items: [
                .highlightedDescription(text: "manage_account.manual_backup_required.description".localized, style: .warning),
            ],
            buttons: [
                .init(style: .yellow, title: "manage_account.manual_backup_required.button".localized) {
                    isPresented.wrappedValue = false

                    Coordinator.shared.performAfterUnlock {
                        presentBackup(reason: .deleteCloudBackup)
                    }
                },
                .init(style: .transparent, title: "button.cancel".localized) {
                    isPresented.wrappedValue = false
                },
            ],
            isPresented: isPresented
        )
    }

    private func presentBackup(reason: BackupReason) {
        Coordinator.shared.present { _ in
            BackupView(account: viewModel.account) {
                switch reason {
                case .deleteCloudBackup: deleteCloudBackup()
                default: ()
                }
            }
            .ignoresSafeArea()
        }
        stat(page: .manageWallet, event: .open(page: .manualBackup))
    }

    private func deleteCloudBackup() {
        do {
            try viewModel.deleteCloudBackup()
            HudHelper.instance.show(banner: .deleted)
            stat(page: .manageWallet, event: .delete(entity: .cloudBackup))
        } catch {
            HudHelper.instance.show(banner: .error(string: "backup.cloud.cant_delete_file".localized))
        }
    }

    private func unlink() {
        viewModel.deleteAccount()
        HudHelper.instance.show(banner: .deleted)
        isPresented = false
    }
}

extension ManageAccountView {
    enum BackupReason: Identifiable {
        case manual
        case deleteCloudBackup

        var id: Self { self }
    }

    struct UnlinkView: View {
        @Binding var isPresented: Bool
        let onUnlink: () -> Void

        @State private var checkedIndices = Set<Int>()

        private let items = [
            "settings_manage_keys.delete.confirmation_remove".localized,
            "settings_manage_keys.delete.confirmation_loose".localized,
        ]

        var body: some View {
            VStack(spacing: 0) {
                BottomSheetView.TitleView(
                    icon: .trash,
                    title: "settings_manage_keys.delete.title".localized,
                    isPresented: $isPresented
                )

                ListSection {
                    ForEach(0 ..< items.count, id: \.self) { index in
                        ClickableRow(action: {
                            if checkedIndices.contains(index) {
                                checkedIndices.remove(index)
                            } else {
                                checkedIndices.insert(index)
                            }
                        }) {
                            Image(checkedIndices.contains(index) ? "checkbox_active_24" : "checkbox_diactive_24")
                            Text(items[index]).themeSubhead2(color: .themeLeah)
                        }
                    }
                }
                .themeListStyle(.bordered)
                .padding(.horizontal, .margin16)
                .padding(.bottom, .margin24)

                VStack(spacing: .margin12) {
                    Button(
                        action: onUnlink,
                        label: {
                            Text("security_settings.delete_alert_button".localized)
                        }
                    )
                    .buttonStyle(PrimaryButtonStyle(style: .red))
                    .disabled(checkedIndices.count < items.count)
                }
                .padding(.horizontal, .margin24)
            }
            .padding(.bottom, .margin24)
        }
    }
}
