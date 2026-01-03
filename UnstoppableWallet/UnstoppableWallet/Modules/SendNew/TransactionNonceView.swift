import Foundation
import MarketKit
import SwiftUI

struct TransactionNonceView: View {
    @StateObject private var viewModel: TransactionNonceViewModel
    private var helper = FeeSettingsViewHelper()

    @Environment(\.presentationMode) private var presentationMode
    @FocusState private var isFocused: Bool

    init(service: EvmTransactionService) {
        _viewModel = .init(wrappedValue: TransactionNonceViewModel(service: service))
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                BottomGradientWrapper {
                    ScrollView {
                        VStack(spacing: 24) {
                            ThemeText("evm_send_settings.nonce.info".localized, style: .subhead)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)

                            helper.inputNumberWithSteps(
                                placeholder: "",
                                text: viewModel.nonce,
                                cautionState: $viewModel.nonceCautionState,
                                onTap: viewModel.stepChangeNonce
                            )
                            .focused($isFocused)

                            let cautions = viewModel.cautions
                            if !cautions.isEmpty {
                                VStack(spacing: .margin12) {
                                    ForEach(cautions.indices, id: \.self) { index in
                                        AlertCardView(caution: cautions[index])
                                    }
                                }
                            }
                        }
                        .padding(EdgeInsets(top: 12, leading: 16, bottom: 32, trailing: 16))
                    }
                } bottomContent: {
                    ThemeButton(text: "button.apply".localized) {
                        viewModel.apply()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(!viewModel.applyEnabled)
                }
            }
            .onTapGesture {
                isFocused = false
            }
            .animation(.default, value: viewModel.nonceCautionState)
            .navigationTitle("evm_send_settings.nonce".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("button.reset".localized) {
                        viewModel.onReset()
                    }
                    .foregroundStyle(viewModel.resetEnabled ? Color.themeJacob : Color.themeGray)
                    .disabled(!viewModel.resetEnabled)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("button.cancel".localized) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
