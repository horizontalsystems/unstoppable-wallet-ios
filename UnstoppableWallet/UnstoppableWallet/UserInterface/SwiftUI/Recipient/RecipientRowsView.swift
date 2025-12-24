import MarketKit
import SwiftUI

struct RecipientRowsView: View {
    @StateObject var viewModel: RecipientRowsViewModel

    init(value: String, customTitle: String? = nil, blockchainType: BlockchainType) {
        _viewModel = StateObject(wrappedValue: RecipientRowsViewModel(address: value, customTitle: customTitle, blockchainType: blockchainType))
    }

    var body: some View {
        Cell(
            left: {
                ThemeImage(viewModel.item.icon, size: .iconSize24)
            },
            middle: {
                MultiText(subtitle: ComponentText(text: viewModel.item.title, colorStyle: .primary), description: viewModel.item.subtitle)
            }
        )
    }
}
