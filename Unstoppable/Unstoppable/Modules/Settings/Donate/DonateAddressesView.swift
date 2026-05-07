import Kingfisher
import MarketKit
import SwiftUI

struct DonateAddressesView: View {
    @StateObject private var viewModel = DonateAddressViewModel()

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                ForEach(viewModel.viewItems) { item in
                    VStack(spacing: 0) {
                        ListSectionHeader(text: item.name)

                        ListSection {
                            ListRow {
                                content(blockchainType: item.type, address: item.address)
                            }
                        }
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("donate.list.get_address.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.editor)
    }

    @ViewBuilder func content(blockchainType: BlockchainType, address: String) -> some View {
        HStack(spacing: .margin16) {
            KFImage.url(URL(string: blockchainType.imageUrl))
                .resizable()
                .placeholder { RoundedRectangle(cornerRadius: .cornerRadius8).fill(Color.themeBlade) }
                .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8))
                .frame(width: .iconSize32, height: .iconSize32)

            Text(address).textSubhead2(color: .themeLeah)

            Button {
                CopyHelper.copyAndNotify(value: address)
            } label: {
                Image("copy_20").renderingMode(.template)
            }
            .buttonStyle(SecondaryCircleButtonStyle())
        }
    }
}
