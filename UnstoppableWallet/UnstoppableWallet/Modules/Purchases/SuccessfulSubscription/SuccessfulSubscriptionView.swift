import SwiftUI

struct SuccessfulSubscriptionView: View {
    @StateObject var viewModel: PurchasesViewModel
    @Binding var isPresented: Bool

    var body: some View {
        ThemeRadialView {
            VStack(spacing: 0) {
                Image("box_2")

                Text("purchases.successful_subscription.description".localized)
                    .textHeadline1(color: .themeLeah)
                    .multilineTextAlignment(.center)
                    .padding(.top, .margin24)
                    .padding(.horizontal, 52)

                activatedDescription()
                Spacer()

                VStack(spacing: .margin8) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("purchases.successful_subscription.button.go_app".localized)
                    }
                    .buttonStyle(PrimaryButtonStyle(style: .yellowGradient))
                }
            }
            .padding(EdgeInsets(top: .margin24, leading: .margin24, bottom: .margin12, trailing: .margin24))
        }
    }

    private func activatedDescription() -> some View {
        Text("purchases.successful_subscription.subscribed".localized)
            .textSubhead2(color: .themeJacob)
            .multilineTextAlignment(.center)
            .padding(.horizontal, .margin32)
            .padding(.top, .margin12)
            .padding(.bottom, .margin32)
    }
}
