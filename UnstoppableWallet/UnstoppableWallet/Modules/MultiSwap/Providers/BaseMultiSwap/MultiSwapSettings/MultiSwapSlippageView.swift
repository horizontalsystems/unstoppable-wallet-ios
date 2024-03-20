import MarketKit
import SwiftUI

struct MultiSwapSlippageView: View {
    @ObservedObject var viewModel: SlippageMultiSwapSettingsViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("swap.advanced_settings.slippage".localized).textSubhead1()
                Spacer()
            }
            .padding(EdgeInsets(top: .margin6, leading: .margin16, bottom: .margin6, trailing: .margin16))

            inputWithShortCuts(
                placeholder: MultiSwapSlippage.default.description,
                text: $viewModel.slippageString,
                cautionState: $viewModel.slippageCautionState,
                onTap: { viewModel.stepSlippage(direction: $0) }
            )

            Text("swap.advanced_settings.slippage.footer".localized)
                .themeSubhead2()
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin16))
        }
    }

    @ViewBuilder private func inputWithShortCuts(placeholder: String = "", text: Binding<String>, cautionState: Binding<CautionState>, onTap: @escaping (StepChangeButtonsViewDirection) -> Void) -> some View {
        InputTextRow(vertical: .margin8) {
            StepChangeButtonsView(content: {
                InputTextView(
                    placeholder: placeholder,
                    text: text
                )
                .font(.themeBody)
                .keyboardType(.decimalPad)
                .autocorrectionDisabled()
            }, onTap: onTap)
        }
        .modifier(CautionBorder(cautionState: cautionState))
        .modifier(CautionPrompt(cautionState: cautionState))
    }
}
