import SwiftUI

struct BackupContentListView: View {
    let description: String
    let walletItems: [BackupModule.WalletItem]
    let dataItems: [BackupModule.DataItem]
    @Binding var selectedWalletIds: Set<String>
    @Binding var selectedDataSections: Set<BackupSection>
    let buttonTitle: String
    let onAction: () -> Void

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                ScrollView {
                    VStack(spacing: .margin24) {
                        HStack {
                            ThemeText(description, style: .subhead)
                            Spacer()
                        }
                        .padding(.horizontal, .margin16)

                        if !walletItems.isEmpty {
                            ListSection(header: "backup_content.header.wallets".localized, uppercased: false) {
                                ForEach(walletItems) { item in
                                    walletRow(item: item)
                                }
                            }
                        }

                        if !dataItems.isEmpty {
                            ListSection(header: "backup_content.header.data".localized, uppercased: false) {
                                ForEach(dataItems) { item in
                                    dataRow(item: item)
                                }
                            }
                        }
                    }
                    .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                }
            } bottomContent: {
                Button(action: onAction) {
                    Text(buttonTitle)
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
                .disabled(selectedWalletIds.isEmpty && selectedDataSections.isEmpty)
            }
        }
    }

    @ViewBuilder
    private func walletRow(item: BackupModule.WalletItem) -> some View {
        let isSelected = selectedWalletIds.contains(item.accountId)

        Cell(
            middle: {
                MultiText(
                    title: item.name,
                    subtitle: ComponentText(text: item.subtitle, colorStyle: item.cautionType?.colorStyle)
                )
            },
            right: {
                Image.checkbox(active: isSelected)
            },
            action: {
                toggleWallet(id: item.accountId)
            }
        )
    }

    @ViewBuilder
    private func dataRow(item: BackupModule.DataItem) -> some View {
        let isSelected = selectedDataSections.contains(item.section)

        Cell(
            middle: {
                MultiText(title: item.title, subtitle: item.subtitle)
            },
            right: {
                Image.checkbox(active: isSelected)
            },
            action: {
                toggleSection(item.section)
            }
        )
    }

    private func toggleWallet(id: String) {
        if selectedWalletIds.contains(id) {
            selectedWalletIds.remove(id)
        } else {
            selectedWalletIds.insert(id)
        }
    }

    private func toggleSection(_ section: BackupSection) {
        if selectedDataSections.contains(section) {
            selectedDataSections.remove(section)
        } else {
            selectedDataSections.insert(section)
        }
    }
}
