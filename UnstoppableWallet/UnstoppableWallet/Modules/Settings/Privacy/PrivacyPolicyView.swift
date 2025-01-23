import SwiftUI

struct PrivacyPolicyView: View {
    @StateObject var viewModel: PrivacyPolicyViewModel

    @State var subscriptionPresented = false

    init(config: PrivacyPolicyViewModel.Config) {
        _viewModel = StateObject(wrappedValue: PrivacyPolicyViewModel(config: config))
    }

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                HighlightedTextView(text: viewModel.config.description)

                VStack(spacing: 0) {
                    PremiumListSectionHeader()
                    ListSection {
                        premiumRow(statsRow())
                    }
                    .modifier(ColoredBorder())
                    ListSectionFooter(text: "settings.privacy.allow.description".localized)
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            .sheet(isPresented: $subscriptionPresented) {
                PurchasesView()
            }
        }
        .navigationTitle("settings.privacy".localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private func premiumRow(_ view: some View) -> some View {
        if viewModel.premiumEnabled {
            ListRow {
                view
            }
        } else {
            ClickableRow {
                subscriptionPresented = true
            } content: {
                view
            }
        }
    }

    @ViewBuilder private func statsRow() -> some View {
        Toggle(isOn: Binding(get: { viewModel.statsEnabled }, set: { viewModel.set(allowed: $0) })) {
            HStack(spacing: .margin16) {
                Image("share_1_24").themeIcon(color: .themeJacob)
                Text("settings.privacy.allow".localized).themeBody()
            }
        }
        .allowsHitTesting(viewModel.premiumEnabled)
        .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
    }
}
