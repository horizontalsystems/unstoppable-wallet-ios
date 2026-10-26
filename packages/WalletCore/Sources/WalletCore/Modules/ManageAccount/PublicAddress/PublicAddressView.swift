import SwiftUI

struct PublicAddressView: View {
    @StateObject private var viewModel: PublicAddressViewModel

    init(kind: PublicAddressKind, account: Account) {
        _viewModel = StateObject(wrappedValue: PublicAddressViewModel(kind: kind, account: account))
    }

    var body: some View {
        KeyScreenScaffold(
            title: viewModel.kind.title,
            statPage: viewModel.kind.statPage,
            showsInfoButton: false,
            buttonDisabled: viewModel.address.isEmpty,
            onButtonTap: { viewModel.copy() }
        ) {
            KeyCardView(text: viewModel.address)
        }
    }
}
