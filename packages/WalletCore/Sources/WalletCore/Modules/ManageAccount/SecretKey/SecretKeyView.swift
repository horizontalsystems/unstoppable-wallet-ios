import SwiftUI

struct SecretKeyView: View {
    @StateObject private var viewModel: SecretKeyViewModel

    init(kind: SecretKeyKind, accountType: AccountType) {
        _viewModel = StateObject(wrappedValue: SecretKeyViewModel(kind: kind, accountType: accountType))
    }

    var body: some View {
        KeyScreenScaffold(
            title: viewModel.kind.title,
            statPage: viewModel.kind.statPage,
            copyDisabled: viewModel.key.isEmpty,
            onCopy: { viewModel.copy() }
        ) {
            VStack(spacing: .margin12) {
                AlertCardView(.init(text: "recovery_phrase.warning".localized(AppConfig.appName), type: .caution, style: .inline))

                KeyCardView(
                    text: viewModel.key,
                    hidden: viewModel.hidden,
                    hint: viewModel.kind.hint,
                    onTap: { viewModel.toggleHidden() }
                )
            }
        }
    }
}
