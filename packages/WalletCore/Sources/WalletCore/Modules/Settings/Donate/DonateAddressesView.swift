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
                            content(blockchainType: item.type, address: item.address)
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
        Cell(
            left: {
                KFImage.url(URL(string: blockchainType.imageUrl))
                    .resizable()
                    .placeholder { RoundedRectangle(cornerRadius: .cornerRadius8).fill(Color.themeBlade) }
                    .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8))
                    .frame(width: .iconSize32, height: .iconSize32)
            },
            middle: { ThemeText(address, style: .subhead, colorStyle: .primary) },
            right: {
                Button {
                    CopyHelper.copyAndNotify(value: address)
                } label: {
                    Image("copy").buttonIcon(size: .iconSize20)
                }
                .buttonStyle(SecondaryCircleButtonStyle())
            }
        )
    }
}
