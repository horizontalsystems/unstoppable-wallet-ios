import MarketKit
import SwiftUI

public struct MultiSwapSlippageView: View {
    @StateObject var viewModel: MultiSwapSlippageViewModel
    @Environment(\.presentationMode) private var presentationMode

    private let onChange: (Decimal) -> Void

    @FocusState private var isFocused: Bool

    public init(slippage: Decimal, onChange: @escaping (Decimal) -> Void) {
        _viewModel = .init(wrappedValue: MultiSwapSlippageViewModel(initialSlippage: slippage))
        self.onChange = onChange
    }

    public var body: some View {
        ThemeNavigationStack {
            ThemeView {
                BottomGradientWrapper {
                    ScrollView {
                        VStack(spacing: 24) {
                            ThemeText("swap.advanced_settings.slippage.info".localized, style: .subhead)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)

                            ThemeInput(
                                caution: viewModel.slippageCautionState,
                                buttons: ThemeInputButton.steps(minusIdentifier: TestTags.slippageMinus, plusIdentifier: TestTags.slippagePlus) {
                                    viewModel.stepSlippage(direction: $0)
                                }
                            ) {
                                InputTextView(
                                    placeholder: MultiSwapSlippage.default.description,
                                    text: $viewModel.slippageString
                                )
                                .keyboardType(.decimalPad)
                                .autocorrectionDisabled()
                                .focused($isFocused)
                                .accessibilityIdentifier(TestTags.slippageInput)
                            }
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
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        viewModel.reset()
                    }) {
                        Image("reset")
                    }
                    .disabled(!viewModel.resetEnabled)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image("close")
                    }
                }
            }
        }
    }
}
