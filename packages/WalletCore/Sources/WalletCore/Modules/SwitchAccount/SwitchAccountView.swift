import SwiftUI

struct SwitchAccountView: View {
    @StateObject var viewModel = SwitchAccountViewModel()

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: .margin16) {
                Image("switch_wallet_24")
                    .themeIcon(color: .themeJacob)
                    .frame(width: .iconSize24, height: .iconSize24)

                Text("switch_account.title".localized).themeHeadline2()

                IconButton(icon: "close", style: .secondary, mode: .transparent, size: .small) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .padding(.horizontal, .margin32)
            .padding(.vertical, .margin24)

            ScrollView {
                VStack(spacing: 0) {
                    section(title: "switch_account.wallets".localized, viewItems: viewModel.regularViewItems, watch: false)
                    section(title: "switch_account.watch_wallets".localized, viewItems: viewModel.watchViewItems, watch: true)
                }
                .padding(EdgeInsets(top: 0, leading: .margin16, bottom: .margin16, trailing: .margin16))
            }
        }
        .frame(maxHeight: UIScreen.main.bounds.height - UIScreen.main.bounds.height * 15 / 100)
    }

    @ViewBuilder private func section(title: String, viewItems: [SwitchAccountViewModel.ViewItem], watch: Bool) -> some View {
        if !viewItems.isEmpty {
            VStack(spacing: 0) {
                ListSectionHeader(text: title)

                ListSection {
                    ForEach(viewItems.indices, id: \.self) { index in
                        row(viewItem: viewItems[index], watch: watch)
                    }
                }
                .themeListStyle(.bordered)
            }
            .padding(.bottom, .margin16)
        }
    }

    private func row(viewItem: SwitchAccountViewModel.ViewItem, watch: Bool) -> some View {
        Cell(
            left: { Image.checkbox(active: viewItem.selected) },
            middle: { MultiText(title: viewItem.title, subtitle: viewItem.subtitle) },
            right: {
                if watch {
                    ThemeImage("binocular", size: .iconSize20)
                }
            },
            action: {
                viewModel.onSelect(accountId: viewItem.accountId)
                presentationMode.wrappedValue.dismiss()
            }
        )
    }
}
