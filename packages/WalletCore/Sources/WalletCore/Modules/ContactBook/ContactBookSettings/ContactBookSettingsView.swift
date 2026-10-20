import SwiftUI
import UniformTypeIdentifiers

struct ContactBookSettingsView: View {
    @StateObject private var viewModel = ContactBookSettingsViewModel()
    @Binding private var isPresented: Bool

    @State private var restorePickerPresented = false

    init(isPresented: Binding<Bool>) {
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack {
            ScrollableThemeView {
                VStack(spacing: .margin24) {
                    ListSection {
                        ClickableRow(action: {
                            restorePickerPresented = true
                        }) {
                            ThemeImage("arrow_in", size: .iconSize24, colorStyle: .yellow)
                            Text("contacts.settings.restore_contacts".localized).themeBody(color: .themeJacob)
                        }

                        if viewModel.hasContacts {
                            ClickableRow(action: {
                                backup()
                            }) {
                                ThemeImage("cloud", size: .iconSize24, colorStyle: .yellow)
                                Text("contacts.settings.backup_contacts".localized).themeBody(color: .themeJacob)
                            }
                        }
                    }

                    ListSection(footer: "contacts.settings.description".localized) {
                        ListRow {
                            Text("contacts.settings.icloud_sync".localized).themeBody()

                            Spacer()

                            if viewModel.syncEnabled, viewModel.lostSynchronization {
                                ThemeImage("warning", size: .iconSize20, colorStyle: .red)
                            }

                            ThemeToggle(isOn: viewModel.toggleOn, onToggle: viewModel.onToggle)
                        }
                    }

                    if viewModel.lostSynchronization {
                        AlertCardView(.init(text: "contacts.settings.lost_synchronization.description".localized, type: .critical, style: .inline))
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            }
            .navigationTitle("contacts.settings.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image("close")
                    }
                }
            }
        }
        .fileImporter(isPresented: $restorePickerPresented, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
            viewModel.didPick(result: result)
        }
        .onReceive(viewModel.mergeConfirmationSubject) {
            presentMergeConfirmation()
        }
        .onChange(of: restorePickerPresented) { _, _ in
            presentPendingRestoreIfNeeded()
        }
        .onChange(of: viewModel.pendingRestore != nil) { _, _ in
            presentPendingRestoreIfNeeded()
        }
        .onReceive(viewModel.restoredSubject) {
            HudHelper.instance.show(banner: .success(string: "contacts.restore.restored".localized))
            isPresented = false
        }
        .onReceive(viewModel.errorSubject) { error in
            HudHelper.instance.show(banner: .error(string: error))
        }
    }

    private func backup() {
        guard let url = viewModel.createBackupFile() else {
            return
        }

        Coordinator.shared.present { _ in
            ActivityView(activityItems: [url])
        }
    }

    private func presentMergeConfirmation() {
        let confirmation = ContactBookConfirmation()

        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            BottomSheetView(
                items: [
                    .title(icon: ThemeImage.warning, title: "alert.warning".localized),
                    .warning(text: "contacts.settings.merge_disclaimer".localized),
                    .buttonGroup(.init(buttons: [
                        .init(style: .yellow, title: "button.continue".localized) {
                            confirmation.confirmed = true
                            viewModel.confirmMerge()
                            isPresented.wrappedValue = false
                        },
                        .init(style: .transparent, title: "button.cancel".localized) {
                            isPresented.wrappedValue = false
                        },
                    ])),
                ]
            )
        } onDismiss: {
            if !confirmation.confirmed {
                viewModel.cancelMerge()
            }
        }
    }

    private func presentPendingRestoreIfNeeded() {
        guard !restorePickerPresented, let contacts = viewModel.pendingRestore else {
            return
        }

        viewModel.pendingRestore = nil
        presentRestoreConfirmation(contacts: contacts)
    }

    private func presentRestoreConfirmation(contacts: [BackupContact]) {
        let confirmation = ContactBookConfirmation()

        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            BottomSheetView(
                items: [
                    .title(icon: ThemeImage.warning, title: "alert.warning".localized),
                    .warning(text: "contacts.restore.overwrite_alert.description".localized),
                    .buttonGroup(.init(buttons: [
                        .init(style: .red, title: "contacts.restore.overwrite_alert.replace".localized) {
                            confirmation.confirmed = true
                            isPresented.wrappedValue = false
                        },
                        .init(style: .transparent, title: "button.cancel".localized) {
                            isPresented.wrappedValue = false
                        },
                    ])),
                ]
            )
        } onDismiss: {
            if confirmation.confirmed {
                viewModel.restore(contacts: contacts)
            }
        }
    }
}
