import MarketKit
import SwiftUI

struct AddressRowsView: View {
    @StateObject var viewModel: RecipientRowsViewModel

    init(value: String, blockchainType: BlockchainType) {
        _viewModel = StateObject(wrappedValue: RecipientRowsViewModel(address: value, blockchainType: blockchainType))
    }

    var body: some View {
        Cell(
            left: {
                ThemeImage(viewModel.item.icon, size: .iconSize24)
                    .padding(4)
            },
            middle: {
                MultiText(eyebrow: ComponentText(text: viewModel.item.title, colorStyle: .primary), subtitle: viewModel.item.subtitle)
            }
        )
    }
}

struct RecipientRowsView: View {
    @StateObject var viewModel: RecipientRowsViewModel
    private let title: String
    private let value: String
    private let copyable: Bool

    init(title: String, value: String, copyable: Bool, blockchainType: BlockchainType) {
        _viewModel = StateObject(wrappedValue: RecipientRowsViewModel(address: value, blockchainType: blockchainType))
        self.title = title
        self.value = value
        self.copyable = copyable
    }

    var body: some View {
        Cell(
            style: .secondary,
            middle: {
                MiddleTextIcon(text: title)
            },
            right: {
                if copyable {
                    RightButtonText(text: viewModel.item.title.shortened, icon: "copy_filled") {
                        CopyHelper.copyAndNotify(value: value)
                    }
                } else {
                    RightMultiText(subtitle: ComponentText(text: viewModel.item.title.shortened, colorStyle: .primary))
                }
            }
        )
    }
}
