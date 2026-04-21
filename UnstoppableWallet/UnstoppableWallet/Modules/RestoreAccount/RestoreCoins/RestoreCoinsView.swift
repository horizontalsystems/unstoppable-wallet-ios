import Kingfisher
import MarketKit
import SwiftUI

struct RestoreCoinsView: View {
    @StateObject private var viewModel: RestoreCoinsViewModel
    @Binding private var isParentPresented: Bool

    init(
        accountName: String,
        accountType: AccountType,
        isManualBackedUp: Bool = true,
        isFileBackedUp: Bool = false,
        isParentPresented: Binding<Bool>
    ) {
        _viewModel = StateObject(wrappedValue: RestoreCoinsViewModel(
            accountName: accountName,
            accountType: accountType,
            isManualBackedUp: isManualBackedUp,
            isFileBackedUp: isFileBackedUp
        ))
        _isParentPresented = isParentPresented
    }

    var body: some View {
        ThemeView(style: .list) {
            BottomGradientWrapper(gradientColor: .themeLawrence) {
                ScrollView {
                    VStack(spacing: 0) {
                        ThemeText("restore_select.description".localized, style: .subhead)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 32)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.themeTyler)
                            .themeListTopView()

                        ListSection {
                            ForEach(viewModel.items) { item in
                                cell(item: item)
                            }
                        }
                        .themeListStyle(.transparent)
                    }
                    .padding(EdgeInsets(top: 12, leading: 0, bottom: 32, trailing: 0))
                }
                .themeListScrollHeader()
            } bottomContent: {
                ThemeButton(text: "button.restore".localized) {
                    viewModel.restore()

                    HudHelper.instance.show(banner: .imported)
                    isParentPresented = false
                }
                .disabled(!viewModel.canRestore)
            }
        }
        .navigationTitle("restore_select.title".localized)
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
