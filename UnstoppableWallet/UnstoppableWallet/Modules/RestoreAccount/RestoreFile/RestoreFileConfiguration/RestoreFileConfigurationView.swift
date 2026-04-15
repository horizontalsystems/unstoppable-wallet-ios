import SwiftUI

struct RestoreFileConfigurationView: View {
    @StateObject private var viewModel: RestoreFileConfigurationViewModel
    @Binding var isParentPresented: Bool

    init(rawBackup: RawFullBackup, backupName: String, isParentPresented: Binding<Bool>, statPage: StatPage) {
        _viewModel = StateObject(wrappedValue: RestoreFileConfigurationViewModel(
            cloudBackupManager: Core.shared.cloudBackupManager,
            appBackupProvider: Core.shared.appBackupProvider,
            contactBookManager: Core.shared.contactManager,
            statPage: statPage,
            rawBackup: rawBackup,
            backupName: backupName
        ))
        _isParentPresented = isParentPresented
    }

    var body: some View {
        BackupContentListView(
            description: "backup_content.description.restore".localized,
            walletItems: viewModel.walletItems,
            dataItems: viewModel.dataItems,
            selectedWalletIds: $viewModel.selectedWalletIds,
            selectedDataSections: $viewModel.selectedDataSections,
            buttonTitle: "button.restore".localized,
            onAction: {
                viewModel.onTapRestore()
            }
        )
        .navigationTitle(viewModel.backupTitle)
        .onReceive(viewModel.showMergeAlertPublisher) {
            Coordinator.shared.present(type: .bottomSheet) { sheetPresented in
                BottomSheetView(
                    items: [
                        .title(icon: ThemeImage.warning, title: "alert_card.title.caution".localized),
                        .text(text: "backup_app.restore.notice.description".localized),
                        .buttonGroup(.init(buttons: [
                            .init(style: .gray, title: "button.replace".localized) {
                                sheetPresented.wrappedValue = false
                                viewModel.restore()
                            },
                            .init(style: .transparent, title: "button.cancel".localized) {
                                sheetPresented.wrappedValue = false
                            },
                        ])),
                    ]
                )
            }
        }
        .onReceive(viewModel.finishedPublisher) { success in
            if success {
                HudHelper.instance.show(banner: .done)
                isParentPresented = false
            }
        }
    }
}
