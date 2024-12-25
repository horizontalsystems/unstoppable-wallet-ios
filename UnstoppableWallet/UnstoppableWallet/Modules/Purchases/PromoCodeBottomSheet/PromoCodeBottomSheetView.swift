import Chart
import MarketKit
import SwiftUI

struct PromoCodeBottomSheetView: View {
    @StateObject private var viewModel: PromoCodeBottomSheetViewModel

    @Binding private var isPresented: Bool
    @FocusState private var focusField: FocusField?

    init(promo: String, isPresented: Binding<Bool>, onApplyPromo: @escaping ((PurchaseManager.PromoData) -> ())) {
        _viewModel = StateObject(wrappedValue: PromoCodeBottomSheetViewModel(promo: promo, onApplyPromo: onApplyPromo))
        
        _isPresented = isPresented
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: .margin16) {
                Image("percent_24").themeIcon(color: .themeJacob)
                Text("purchases.promocode.title".localized).themeHeadline2()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image("close_3_24")
                }
            }
            .padding(.horizontal, .margin32)
            .padding(.top, .margin24)
            .padding(.bottom, .margin12)
            
            InputTextRow(vertical: .margin8) {
                ShortcutButtonsView(
                    content: {
                        TextField(
                            "purchases.promocode.placeholder".localized,
                            text: $viewModel.promocode
                        )
                        .focused($focusField, equals: .promocode)
                        
                        .accentColor(.themeYellow)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .font(.themeBody)
                    },
                    showDelete: .init(get: { !viewModel.promocode.isEmpty }, set: { _ in }),
                    items: viewModel.shortcuts,
                    onTap: {
                        viewModel.onTap(index: $0)
                    }, onTapDelete: {
                        viewModel.onTapDelete()
                    }
                )
            }
            .modifier(CautionBorder(cautionState: $viewModel.promocodeCautionState))
            .padding(EdgeInsets(top: .margin24, leading: .margin16, bottom: 0, trailing: .margin16))
            
            VStack(spacing: .margin12) {
                buttonView()
            }
            .padding(EdgeInsets(top: .margin24, leading: .margin24, bottom: 0, trailing: .margin24))
        }
        .onFirstAppear {
            focusField = .promocode
        }
    }
    
    @ViewBuilder private func buttonView() -> some View {
        let (title, disabled, showProgress) = buttonState()

        Button(action: {
            viewModel.applyPromo()
            isPresented = false
        }) {
            HStack(spacing: .margin8) {
                if showProgress {
                    ProgressView()
                }

                Text(title)
            }
        }
        .disabled(disabled)
        .buttonStyle(PrimaryButtonStyle(style: .yellow))
    }

    private func buttonState() -> (String, Bool, Bool) {
        var title: String = "button.apply".localized
        var disabled = true
        var showProgress = false

        switch viewModel.buttonState {
        case .idle: ()
        case .loading:
            showProgress = true
        case .apply:
            disabled = false
        case .invalid:
            title = "purchases.promocode.button.invalid".localized
        case .alreadyUsed:
            title = "purchases.promocode.button.already_used".localized
        }

        return (title, disabled, showProgress)
    }

}

extension PromoCodeBottomSheetView {
    private enum FocusField: Int, Hashable {
        case promocode
    }
}
