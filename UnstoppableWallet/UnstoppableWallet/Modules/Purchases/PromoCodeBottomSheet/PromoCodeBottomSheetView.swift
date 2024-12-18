import Chart
import MarketKit
import SwiftUI

struct PromoCodeBottomSheetView: View {
    @StateObject private var viewModel: PromoCodeBottomSheetViewModel

    @Binding private var isPresented: Bool
    @FocusState private var isFocused: Bool

    init(isPresented: Binding<Bool>, onSubscribe: @escaping () -> ()) {
        _viewModel = StateObject(wrappedValue: PromoCodeBottomSheetViewModel(onSubscribe: onSubscribe))

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
                        InputTextView(
                            placeholder: "backup.cloud.name.placeholder".localized,
                            text: $viewModel.promocode
                        )
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($isFocused)
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
            .modifier(CautionPrompt(cautionState: $viewModel.promocodeCautionState))
            .padding(EdgeInsets(top: .margin24, leading: .margin16, bottom: 0, trailing: .margin16))
            
            VStack(spacing: .margin12) {
                Button(action: {
                    print("Tap apply")
                }) {
                    Text("button.apply".localized)
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
            }
            .padding(EdgeInsets(top: .margin24, leading: .margin24, bottom: 0, trailing: .margin24))
        }
        .onAppear {
            isFocused = true
        }
    }

}
