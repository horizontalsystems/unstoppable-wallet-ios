import SwiftUI

struct SuccessfulSubscriptionView: View {
    @Binding var isPresented: Bool

    var body: some View {
        PremiumFactory.background {
            VStack(spacing: 0) {
                PremiumFactory.header(title: PremiumHeaderView.plainTitle("purchases.successful_subscription.description".localized))

                ThemeText("purchases.successful_subscription.subscribed".localized, style: .subhead)
                    .multilineTextAlignment(.center)
                    .padding(EdgeInsets(top: .margin12, leading: .margin32, bottom: .margin24, trailing: .margin32))

                Spacer()
            }
            .safeAreaInset(edge: .bottom) {
                PremiumBottomContent {
                    ThemeButton(text: "purchases.successful_subscription.button.go_app".localized, style: .secondary) {
                        isPresented = false
                    }
                    .accessibilityIdentifier(TestTags.premiumSubscribedGoToApp)
                }
            }
        }
    }
}
