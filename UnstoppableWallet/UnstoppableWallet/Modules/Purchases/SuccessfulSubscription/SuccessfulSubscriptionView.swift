import SwiftUI

struct SuccessfulSubscriptionView: View {
    @Binding var purchasesPresented: Bool

    var body: some View {
        ThemeNavigationStack {
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
                                purchasesPresented = false
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
                            purchasesPresented = false
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
