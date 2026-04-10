import Kingfisher
import MarketKit
import SwiftUI

struct RestoreCoinsView: View {
    @StateObject private var viewModel: RestoreCoinsViewModel

    private let onRestore: () -> Void

    init(
        accountName: String,
        accountType: AccountType,
        isManualBackedUp: Bool = true,
        isFileBackedUp: Bool = false,
        onRestore: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: RestoreCoinsViewModel(
            accountName: accountName,
            accountType: accountType,
            isManualBackedUp: isManualBackedUp,
            isFileBackedUp: isFileBackedUp
        ))
        self.onRestore = onRestore
    }

    var body: some View {
        ThemeView(style: .list) {
            ThemeList(bottomSpacing: 16) {
                ListForEach(viewModel.items) { item in
                    cell(item: item)
                }
            }
        }
        .navigationTitle("restore_select.title".localized)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("button.import".localized) {
                    viewModel.restore(onRestore: onRestore)
                }
                .disabled(!viewModel.canRestore)
                .tint(.themeJacob)
            }
        }
    }

    @ViewBuilder private func cell(item: RestoreCoinsViewModel.Item) -> some View {
        Cell(
            left: {
                KFImage.url(URL(string: item.blockchain.type.imageUrl))
                    .resizable()
                    .placeholder { RoundedRectangle(cornerRadius: 8).fill(Color.themeBlade) }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .frame(size: 32)
            },
            middle: {
                MultiText(
                    title: item.blockchain.name,
                    subtitle: item.blockchain.type.description
                )
            },
            right: {
                HStack(spacing: 8) {
                    if item.hasSettings {
                        IconButton(icon: "edit2_20", style: .secondary, mode: .transparent, size: .small) {
                            viewModel.configure(blockchain: item.blockchain)
                        }
                    }

                    ThemeToggle(
                        isOn: Binding(
                            get: { item.isEnabled },
                            set: { isEnabled in
                                viewModel.toggle(blockchain: item.blockchain, isEnabled: isEnabled)
                            }
                        ).animation(),
                        style: .yellow
                    )
                }
            }
        )
    }
}
