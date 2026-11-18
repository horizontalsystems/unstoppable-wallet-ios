import StoreKit
import SwiftUI

struct PurchasesView: View {
    private static let startScale: CGFloat = 0.9
    @StateObject private var viewModel = PurchasesViewModel()
    @Binding var isPresented: Bool

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                SubscriptionView(viewModel: viewModel)
                    .opacity(viewModel.isSubscriptionSuccessful ? 0 : 1)
                    .scaleEffect(viewModel.isSubscriptionSuccessful ? Self.startScale : 1.0)
                    .overlay(
                        SuccessfulSubscriptionView(isPresented: $isPresented)
                            .opacity(viewModel.isSubscriptionSuccessful ? 1 : 0)
                            .scaleEffect(viewModel.isSubscriptionSuccessful ? 1.0 : Self.startScale)
                    )
                    .animation(.easeInOut(duration: 0.5), value: viewModel.isSubscriptionSuccessful)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image("close")
                    }
                    .accessibilityIdentifier(viewModel.isSubscriptionSuccessful ? TestTags.premiumSubscribedClose : TestTags.premiumClose)
                }
            }
        }
    }
}
