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
                shortCuts: viewModel.slippageShortCuts,
                text: $viewModel.slippage,
                cautionState: $viewModel.slippageCautionState,
                onTap: { viewModel.slippage = viewModel.slippage(at: $0).description },
                onTapDelete: { viewModel.slippage = "" }
            )

            Text("swap.advanced_settings.slippage.footer".localized)
                .themeSubhead2()
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin16))
        }
    }

    @ViewBuilder private func inputWithShortCuts(placeholder: String = "", shortCuts: [ShortCutButtonType], text: Binding<String>, cautionState: Binding<CautionState>, onTap: @escaping (Int) -> Void, onTapDelete: @escaping () -> Void) -> some View {
        InputTextRow(vertical: .margin8) {
            ShortcutButtonsView(
                content: {
                    InputTextView(
                        placeholder: placeholder,
                        text: text
                    )
                    .font(.themeBody)
                    .keyboardType(.decimalPad)
                    .autocorrectionDisabled()
                },
                showDelete: .init(get: { !text.wrappedValue.isEmpty }, set: { _ in }),
                items: shortCuts,
                onTap: {
                    onTap($0)
                }, onTapDelete: {
                    onTapDelete()
                }
            )
        }
        .modifier(CautionBorder(cautionState: cautionState))
        .modifier(CautionPrompt(cautionState: cautionState))
    }
}
