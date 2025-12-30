import MarketKit
import SwiftUI

struct MultiSwapSlippageView: View {
    @StateObject var viewModel: MultiSwapSlippageViewModel
    @Environment(\.presentationMode) private var presentationMode

    private let onChange: (Decimal) -> Void

    @FocusState private var isFocused: Bool

    init(slippage: Decimal, onChange: @escaping (Decimal) -> Void) {
        _viewModel = .init(wrappedValue: MultiSwapSlippageViewModel(initialSlippage: slippage))
        self.onChange = onChange
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                BottomGradientWrapper {
                    ScrollView {
                        VStack(spacing: 24) {
                            ThemeText("swap.advanced_settings.slippage.info".localized, style: .subhead)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)

                            InputTextRow(vertical: .margin8) {
                                StepChangeButtonsView(
                                    content: {
                                        InputTextView(
                                            placeholder: MultiSwapSlippage.default.description,
                                            text: $viewModel.slippageString
                                        )
                                        .font(.themeBody)
                                        .tint(.themeInputFieldTintColor)
                                        .keyboardType(.decimalPad)
                                        .autocorrectionDisabled()
                                        .focused($isFocused)
                                    },
                                    onTap: {
                                        viewModel.stepSlippage(direction: $0)
                                    }
                                )
                            }
                            .modifier(CautionBorder(cautionState: $viewModel.slippageCautionState))
                            .modifier(CautionPrompt(cautionState: $viewModel.slippageCautionState))
                        }
                        .padding(EdgeInsets(top: 12, leading: 16, bottom: 32, trailing: 16))
                    }
                } bottomContent: {
                    ThemeButton(text: "button.apply".localized) {
                        onChange(viewModel.slippage)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(!viewModel.applyEnabled)
                }
            }
            .onTapGesture {
                isFocused = false
            }
            .animation(.default, value: viewModel.slippageCautionState)
            .navigationTitle("swap.advanced_settings.slippage".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("button.reset".localized) {
                        viewModel.reset()
                    }
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
