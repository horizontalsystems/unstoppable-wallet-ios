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

                Button(
                    action: {
                        presentationMode.wrappedValue.dismiss()
                    },
                    label: { Image("close_3_24") }
                )
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
        .frame(maxHeight: UIScreen.main.bounds.height - 200)
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

    @ViewBuilder private func row(viewItem: SwitchAccountViewModel.ViewItem, watch: Bool) -> some View {
        ClickableRow(action: {
            viewModel.onSelect(accountId: viewItem.accountId)
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(viewItem.selected ? "circle_radioon_24" : "circle_radiooff_24")

            VStack(spacing: 1) {
                Text(viewItem.title).themeBody()
                Text(viewItem.subtitle).themeSubhead2()
            }

            if watch {
                Image("binocule_20").themeIcon(color: .themeGray)
            }
        }
    }
}
