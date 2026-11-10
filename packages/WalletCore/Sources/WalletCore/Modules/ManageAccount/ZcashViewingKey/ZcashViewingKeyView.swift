import SwiftUI

struct ZcashViewingKeyView: View {
    @StateObject private var viewModel: ZcashViewingKeyViewModel

    init(accountType: AccountType) {
        _viewModel = StateObject(wrappedValue: ZcashViewingKeyViewModel(accountType: accountType))
    }

    var body: some View {
        KeyScreenScaffold(
            title: "public_keys.zcash_viewing_key".localized,
            statPage: .zcashViewingKey,
            showsInfoButton: false,
            buttonIdentifier: TestTags.zcashViewingKeyCopy,
            buttonDisabled: viewModel.key.isEmpty,
            onButtonTap: { viewModel.copy() }
        ) {
            KeyCardView(text: viewModel.key)
                .accessibilityIdentifier(TestTags.zcashViewingKeyValue)
        }
    }
}
