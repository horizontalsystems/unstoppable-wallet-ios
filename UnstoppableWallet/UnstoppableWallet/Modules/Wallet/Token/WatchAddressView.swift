import SwiftUI

struct WatchAddressView: View {
    @StateObject var viewModel: ReceiveAddressViewModel

    init(wallet: Wallet) {
        _viewModel = StateObject(wrappedValue: ReceiveAddressViewModel.instance(wallet: wallet, type: .legacy))
    }

    var body: some View {
        HStack(spacing: .margin16) {
            ThemeText("balance.token.receive_address".localized, style: .subhead, colorStyle: .secondary)
            Spacer()
            switch viewModel.state {
            case .loading:
                ProgressView()
            case .failed:
                RightTextIcon(
                    text: ComponentText(
                        text: "n/a".localized,
                        colorStyle: .primary
                    ),
                    icon: "arrow_b_right"
                )
            case let .completed(item):
                RightTextIcon(
                    text: ComponentText(
                        text: item.qrItem.address.shortened,
                        colorStyle: .primary
                    ),
                    icon: "arrow_b_right"
                )
            }
        }
    }
}
