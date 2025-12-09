import SwiftUI

struct PremiumFeaturesWrapper: View {
    @StateObject var viewModel = PurchasesViewModel()

    @Binding private var isPresented: Bool
    private let feature: PremiumFeature

    init(isPresented: Binding<Bool>, feature: PremiumFeature) {
        _isPresented = isPresented
        self.feature = feature
    }

    var body: some View {
        PremiumFeaturesInfoBottomSheetView(
            isPresented: $isPresented,
            currentSlideIndex: feature.index,
            buttonTitle: buttonState,
            action: {
                Coordinator.shared.present(type: .bottomSheet) { purchasePresented in
                    PurchaseBottomSheetView(
                        isPresented: purchasePresented,
                        onSubscribe: { _ in }
                    )
                } onDismiss: {
                    isPresented = false
                }
            }
        )
    }

    private var buttonState: String {
        var title = "purchases.button.try".localized

        switch viewModel.buttonState {
        case .tryForFree: ()
        case .activated:
            title = "purchases.button.activated".localized
        case .upgrade:
            title = "purchases.button.upgrade".localized
        }

        return title
    }
}
