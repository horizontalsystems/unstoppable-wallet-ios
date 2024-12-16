import Chart
import MarketKit
import SwiftUI

struct PurchaseBottomSheetView: View {
    @StateObject private var viewModel: PurchaseBottomSheetViewModel

    @Binding private var isPresented: Bool

    private let type: PurchasesViewModel.FeaturesType
    private let onSubscribe: (PurchaseBottomSheetViewModel.Period) -> ()

    init(type: PurchasesViewModel.FeaturesType, isPresented: Binding<Bool>, onSubscribe: @escaping (PurchaseBottomSheetViewModel.Period) -> ()) {
        _viewModel = StateObject(wrappedValue: PurchaseBottomSheetViewModel(onSubscribe: onSubscribe))
        self.type = type
        self.onSubscribe = onSubscribe
        _isPresented = isPresented
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: .margin16) {
                Image(type.icon).themeIcon(color: .themeJacob)
                Text(type.rawValue.uppercased()).themeHeadline2()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image("close_3_24")
                }
            }
            .padding(.horizontal, .margin32)
            .padding(.top, .margin24)
            .padding(.bottom, .margin12)
            
            SubscribePeriodSegmentView(selection: $viewModel.selectedPeriod)
                .onChange(of: viewModel.selectedPeriod) { newValue in
                    viewModel.setPeriod(newValue)
                }
                .padding(.top, .margin12)
                .padding(.horizontal, .margin16)
            
            tryFreeDescription()
                .padding(.horizontal, .margin16)
            
            VStack(spacing: .margin12) {
                Button(action: {
                    onSubscribe(viewModel.selectedPeriod)
                }) {
                    Text("purchases.period.button.try".localized)
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
                
                Button(action: {
                    print("Add promocode")
                }) {
                    Text("purchases.period.button.promo".localized)
                }
                .buttonStyle(PrimaryButtonStyle(style: .transparent))
            }
            .padding(EdgeInsets(top: .margin24, leading: .margin24, bottom: .margin12, trailing: .margin24))
        }
    }

    private func tryFreeDescription() -> some View {
        (
            Text("purchase.period.description1".localized + " ").foregroundColor(.themeRemus).font(.themeSubhead2) +
            Text("purchase.period.description2".localized).foregroundColor(.themeGray).font(.themeSubhead2)
        )
            .multilineTextAlignment(.center)
            .padding(.horizontal, .margin16)
            .padding(.vertical, .margin12)
    }

}
