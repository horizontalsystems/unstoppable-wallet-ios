import SwiftUI

struct SuccessfulSubscriptionView: View {
    @StateObject private var viewModel: PurchasesViewModel

    let onDismissPurchases: () -> Void

    init(onDismissPurchases: @escaping () -> Void) {
        self.onDismissPurchases = onDismissPurchases

        _viewModel = StateObject(wrappedValue: PurchasesViewModel())
    }

    var body: some View {
        ThemeNavigationView {
            ThemeView {
                ThemeRadialView {
                    VStack(spacing: 0) {
                        Image("box_2")
                            .padding(.vertical, .margin24)

                        Text("purchases.successful_subscription.description".localized)
                            .textHeadline1(color: .themeLeah)
                            .multilineTextAlignment(.center)
                            .padding(.top, .margin24)
                            .padding(.horizontal, 52)

                        activatedDescription()
                        Spacer()

                        VStack(spacing: .margin8) {
                            Button(action: {
                                onDismissPurchases()
                            }) {
                                Text("purchases.successful_subscription.button.go_app".localized)
                            }
                            .buttonStyle(PrimaryButtonStyle(style: .yellowGradient))
                        }
                    }
                    .padding(EdgeInsets(top: .margin24, leading: .margin24, bottom: .margin12, trailing: .margin24))
                }
                .navigationTitle("purchases.successful_subscription.title".localized)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("button.close".localized) {
                            onDismissPurchases()
                        }
                    }
                }
            }
        }
        .interactiveDismissDisabled(true)
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
