import SwiftUI

struct RestoreFileConfigurationView: View {
    @StateObject private var viewModel: RestoreFileConfigurationViewModel
    @Binding var isPresented: Bool

    private let onRestore: () -> Void

    init(rawBackup: RawFullBackup, statPage: StatPage, isPresented: Binding<Bool>, onRestore: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: RestoreFileConfigurationViewModel(
            cloudBackupManager: Core.shared.cloudBackupManager,
            appBackupProvider: Core.shared.appBackupProvider,
            contactBookManager: Core.shared.contactManager,
            statPage: statPage,
            rawBackup: rawBackup
        ))
        _isPresented = isPresented
        self.onRestore = onRestore
    }

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                ScrollView {
                    VStack(spacing: .margin24) {
                        HStack {
                            ThemeText("backup_app.backup_list.description.restore".localized, style: .subhead)
                            Spacer()
                        }

                        if !viewModel.accountItems.isEmpty {
                            section(header: "backup_app.backup_list.header.wallets".localized, items: viewModel.accountItems)
                        }

                        if !viewModel.otherItems.isEmpty {
                            ListSection(header: "backup_app.backup_list.header.other".localized) {
                                ForEach(viewModel.otherItems) { item in
                                    row(title: item.title, subtitle: item.description)
                                }
                            }
                        }
                    }
                    .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                }
            } bottomContent: {
                Button(action: {
                    viewModel.onTapRestore()
                }) {
                    Text("button.restore".localized)
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
            }
        }
        .onReceive(viewModel.showMergeAlertPublisher) {
            Coordinator.shared.present(type: .bottomSheet) { sheetPresented in
                BottomSheetView(
                    items: [
                        .title(icon: ThemeImage.warning, title: "alert.notice".localized),
                        .warning(text: "backup_app.restore.notice.description".localized),
                        .buttonGroup(.init(buttons: [
                            .init(style: .red, title: "backup_app.restore.notice.merge".localized) {
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
                onRestore()
            }
        }
        .navigationTitle("backup_app.backup_list.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("button.cancel".localized) {
                    isPresented = false
                }
            }
        }
    }

    @ViewBuilder private func section(header: String, items: [BackupModule.AccountItem]) -> some View {
        ListSection(header: header) {
            ForEach(items, id: \.accountId) {
                item in row(
                    title: item.name,
                    subtitle: ComponentText(text: item.description, colorStyle: item.cautionType?.colorStyle)
                )
            }
        }
    }

    @ViewBuilder private func row(title: CustomStringConvertible, subtitle: CustomStringConvertible?) -> some View {
        Cell(
            middle: {
                MultiText(title: title, subtitle: subtitle)
            },
        )
    }
}
