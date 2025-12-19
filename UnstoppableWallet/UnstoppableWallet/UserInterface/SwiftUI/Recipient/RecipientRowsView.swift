import MarketKit
import SwiftUI

struct RecipientRowsView: View {
    let title: String
    @StateObject var viewModel: RecipientRowsViewModel

    init(title: String, value: String, blockchainType: BlockchainType) {
        self.title = title
        _viewModel = StateObject(wrappedValue: RecipientRowsViewModel(address: value, blockchainType: blockchainType))
    }

    var body: some View {
        Cell(
            style: .secondary,
            middle: {
                MiddleTextIcon(text: title)
            },
            right: {
                RightTextIcon(text: viewModel.name ?? viewModel.label ?? viewModel.address)
            }
        )
    }
}
