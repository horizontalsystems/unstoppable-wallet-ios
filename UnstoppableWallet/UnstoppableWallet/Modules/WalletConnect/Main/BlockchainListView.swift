import Kingfisher
import MarketKit
import SwiftUI

struct BlockchainListView: View {
    let blockchains: [Blockchain]
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ThemeView(style: .list) {
            VStack(spacing: 0) {
                ThemeList(blockchains, bottomSpacing: .margin16) { blockchain in
                    Cell(
                        left: {
                            IconView(url: blockchain.type.imageUrl, placeholderImage: "rectangle_placeholder", type: .squircle)
                        },
                        middle: {
                            ThemeText(blockchain.name, style: .headline2, colorStyle: .primary)
                        },
                    )
                }
            }
        }
        .navigationTitle("wallet_connect.networks".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("button.close".localized) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
