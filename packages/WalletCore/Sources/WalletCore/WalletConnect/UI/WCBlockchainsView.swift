import MarketKit
import SwiftUI

struct WCBlockchainsView: View {
    let blockchainTypes: [BlockchainType]
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ThemeNavigationStack {
            ThemeView(style: .list) {
                ThemeList(blockchainTypes, bottomSpacing: .margin16) { type in
                    Cell(
                        left: {
                            IconView(url: type.imageUrl, placeholderImage: "rectangle_placeholder", type: .squircle)
                        },
                        middle: {
                            ThemeText(WCBlockchainsView.name(type: type), style: .headline2, colorStyle: .primary)
                        },
                    )
                }
            }
            .navigationTitle("wallet_connect.networks".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image("close")
                    }
                }
            }
        }
    }

    static func name(type: BlockchainType) -> String {
        (try? Core.shared.marketKit.blockchain(uid: type.uid))??.name ?? type.uid
    }
}
