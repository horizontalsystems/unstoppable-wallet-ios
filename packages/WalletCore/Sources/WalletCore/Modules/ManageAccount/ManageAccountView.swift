import SwiftUI

struct ManageAccountView: View {
    @StateObject private var viewModel: ManageAccountViewModel
    @StateObject private var accountWarningViewModel: AccountWarningViewModel

    @Binding var isPresented: Bool

    @State private var recoveryPhrasePresented = false
    @State private var privateKeysPresented = false
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
                            .accessibilityIdentifier(TestTags.accountNameInput)
                        }
                    }

                    AccountWarningView(viewModel: accountWarningViewModel)

                    if viewModel.account.backedUp || viewModel.isCloudBackedUp {
                        ListSection {
                            if viewModel.recoveryPhraseVisible {
                                Cell(
                                    left: { ThemeImage("paper_contract", size: .iconSize24) },
                                    middle: { ThemeText("manage_account.recovery_phrase".localized, style: .headline2) },
                                    right: { Image.disclosureIcon },
                                    action: {
                                        Coordinator.shared.performAfterUnlock {
                                            recoveryPhrasePresented = true
                                        }
                                    }
                                )
                            }

                            if viewModel.privateKeysVisible {
                                Cell(
                                    left: { ThemeImage("key", size: .iconSize24) },
                                    middle: { ThemeText("manage_account.private_keys".localized, style: .headline2) },
                                    right: { Image.disclosureIcon },
                                    action: {
                                        Coordinator.shared.performAfterUnlock {
                                            privateKeysPresented = true
                                        }
                                    }
                                )
                            }

                            if viewModel.publicKeysVisible {
                                NavigationLink(destination: {
                                    PublicKeysView(account: viewModel.account)
                                        .onFirstAppear {
                                            stat(page: .manageWallet, event: .open(page: .publicKeys))
                                        }
                                }) {
                                    Cell(
                                        left: { ThemeImage("binocular", size: .iconSize24) },
                                        middle: { ThemeText("manage_account.public_keys".localized, style: .headline2) },
                                        right: { Image.disclosureIcon }
                                    )
                                }
                                .buttonStyle(CellButtonStyle())
                            }
                        }
                    }

                    ListSection(
                        footer: viewModel.account.backedUp || viewModel.isCloudBackedUp ? "manage_account.backup.has_backup_description".localized : "manage_account.backup.no_backup_yet_description".localized
                    ) {
                        if viewModel.account.canBeBackedUp {
                            Cell(
                                left: { ThemeImage("pen", size: .iconSize24, colorStyle: .yellow) },
                                middle: { ThemeText("manage_account.backup_recovery_phrase".localized, style: .headline2, colorStyle: .yellow) },
                                right: {
                                    if viewModel.account.backedUp {
                                        ThemeImage("check", size: .iconSize20, colorStyle: .green)
                                    } else {
                                        ThemeImage("warning", size: .iconSize20, colorStyle: .red)
                                    }
                                },
                                action: {
                                    Coordinator.shared.performAfterUnlock {
                                        presentBackup(reason: .manual)
                                    }
                                }
                            )
                            .accessibilityIdentifier(TestTags.accountManualBackup)
                        }

                        if !viewModel.account.watchAccount {
                            if viewModel.isCloudBackedUp {
                                Cell(
                                    left: { ThemeImage("cloud_off", size: .iconSize24, colorStyle: .red) },
                                    middle: { ThemeText("manage_account.cloud_delete_backup_recovery_phrase".localized, style: .headline2, colorStyle: .red) },
                                    action: {
                                        if viewModel.account.backedUp {
                                            Coordinator.shared.present(type: .bottomSheet) { isPresented in
                                                confirmDeleteCloudBackupView(isPresented: isPresented)
                                            }
                                        } else {
                                            Coordinator.shared.present(type: .bottomSheet) { isPresented in
                                                confirmDeleteCloudBackupAfterManualBackupView(isPresented: isPresented)
                                            }
                                        }
                                    }
                                )
                            } else {
                                Cell(
                                    left: { ThemeImage("cloud", size: .iconSize24, colorStyle: .yellow) },
                                    middle: { ThemeText("manage_account.cloud_backup_recovery_phrase".localized, style: .headline2, colorStyle: .yellow) },
                                    right: {
                                        if !viewModel.account.backedUp {
                                            ThemeImage("warning", size: .iconSize20, colorStyle: .red)
                                        }
                                    },
                                    action: {
                                        Coordinator.shared.presentWalletBackup(account: viewModel.account, statPage: .manageWallet)
                                    }
                                )
                            }
                        }
                    }

                    ListSection {
                        Cell(
                            left: { ThemeImage("trash", size: .iconSize24, colorStyle: .red) },
                            middle: { ThemeText("manage_account.unlink".localized, style: .headline2, colorStyle: .red) },
                            action: {
                                if viewModel.account.watchAccount {
                                    Coordinator.shared.present(type: .bottomSheet) { isPresented in
                                        confirmUnlinkWatchView(isPresented: isPresented)
                                    }
                                } else {
                                    Coordinator.shared.present(type: .bottomSheet) { isPresented in
                                        UnlinkBottomSheetView(isPresented: isPresented) {
                                            unlink()
                                        }
                                    }
                                }
                            }
                        )
                        .accessibilityIdentifier(TestTags.accountUnlink)
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            }
            .onTapGesture {
                isNameFocused = false
            }
            .navigationDestination(isPresented: $recoveryPhrasePresented) {
                RecoveryPhraseView(account: viewModel.account)
                    .onFirstAppear {
                        stat(page: .manageWallet, event: .open(page: .recoveryPhrase))
                    }
            }
            .navigationDestination(isPresented: $privateKeysPresented) {
                PrivateKeysView(account: viewModel.account)
                    .onFirstAppear {
                        stat(page: .manageWallet, event: .open(page: .privateKeys))
                    }
            }
            .navigationTitle(viewModel.account.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image("close")
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        viewModel.save()
                        isPresented = false
                        stat(page: .manageWallet, event: .edit(entity: .walletName))
                    }) {
                        Image("check")
                    }
                    .modifier(ConfirmationButtonStyle())
                    .disabled(viewModel.name.isEmpty || viewModel.account.name == viewModel.name)
                    .accessibilityIdentifier(TestTags.accountSave)
                }
            }
        }
    }

    private func confirmUnlinkWatchView(isPresented _: Binding<Bool>) -> some View {
        BottomSheetView(
            items: [
                .title(icon: ThemeImage.trash, title: "settings_manage_keys.delete.title".localized),
                .text(text: "settings_manage_keys.delete.confirmation_watch".localized),
                .buttonGroup(.init(buttons: [
                    .init(style: .secondary, title: "settings_manage_keys.delete.confirmation_watch.button".localized, identifier: TestTags.unlinkDelete) {
                        unlink()
                    },
                ])),
            ]
        )
    }

    private func confirmDeleteCloudBackupView(isPresented: Binding<Bool>) -> some View {
        BottomSheetView(
            items: [
                .title(icon: ThemeImage.trash, title: "manage_account.cloud_delete_backup_recovery_phrase".localized),
                .text(text: "manage_account.cloud_delete_backup_recovery_phrase.description".localized),
                .buttonGroup(.init(buttons: [
                    .init(style: .secondary, title: "button.delete".localized) {
                        isPresented.wrappedValue = false
                        deleteCloudBackup()
                    },
                    .init(style: .secondary, mode: .transparent, title: "button.cancel".localized) {
                        isPresented.wrappedValue = false
                    },
                ])),
            ]
        )
    }

    private func confirmDeleteCloudBackupAfterManualBackupView(isPresented: Binding<Bool>) -> some View {
        BottomSheetView(
            items: [
                .title(icon: ThemeImage.trash, title: "manage_account.manual_backup_required".localized),
                .warning(text: "manage_account.manual_backup_required.description".localized),
                .buttonGroup(.init(buttons: [
                    .init(style: .secondary, title: "manage_account.manual_backup_required.button".localized) {
                        isPresented.wrappedValue = false

                        Coordinator.shared.performAfterUnlock {
                            presentBackup(reason: .deleteCloudBackup)
                        }
                    },
                    .init(style: .secondary, mode: .transparent, title: "button.cancel".localized) {
                        isPresented.wrappedValue = false
                    },
                ])),
            ]
        )
    }

    private func presentBackup(reason: BackupReason) {
        Coordinator.shared.present { isPresented in
            BackupManualView(account: viewModel.account, isPresented: isPresented) {
                switch reason {
                case .deleteCloudBackup: deleteCloudBackup()
                default: ()
                }
            }
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

        var id: Self {
            self
        }
    }
}
