import MarketKit
import SwiftUI

struct RecipientRowsView: View {
    @StateObject var viewModel: RecipientRowsViewModel
    private let title: String?

    init(title: String? = nil, value: String, blockchainType: BlockchainType) {
        _viewModel = StateObject(wrappedValue: RecipientRowsViewModel(address: value, blockchainType: blockchainType))
        self.title = title
    }

    var body: some View {
        if let title {
            Cell(
                style: .secondary,
                middle: {
                    MiddleTextIcon(text: title)
                },
                right: {
                    RightTextIcon(text: viewModel.item.title.shortened)
                }
            )
        } else {
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
}
