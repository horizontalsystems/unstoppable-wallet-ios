import EvmKit
import Foundation
import MarketKit
import SwiftUI

class FeeSettingsViewHelper {
    func feeAmount(feeToken: Token, currency: Currency, feeTokenRate: Decimal?, loading: Bool, feeData: FeeData?, gasPrice: GasPrice?) -> (FeeSettings.FeeValue, FeeSettings.FeeValue?, FeeSettings.FeeValue) {
        guard !loading else {
            return (.spinner, feeToken.blockchainType.rollupFeeContractAddress.flatMap { _ in .spinner }, .spinner)
        }

        guard case let .evm(evmFeeData) = feeData,
              let l2AmountData = evmFeeData.l2AmountData(gasPrice: gasPrice, feeToken: feeToken, currency: currency, feeTokenRate: feeTokenRate)
        else {
            return (.none, nil, .none)
        }

        let l2Value = FeeSettings.FeeValue.value(
            primary: l2AmountData.appValue.formattedShort() ?? "",
            secondary: l2AmountData.currencyValue.flatMap { ValueFormatter.instance.formatShort(currencyValue: $0) } ?? "n/a".localized
        )

        var l1Value: FeeSettings.FeeValue?

        if let l1AmountData = evmFeeData.l1AmountData(feeToken: feeToken, currency: currency, feeTokenRate: feeTokenRate) {
            l1Value = FeeSettings.FeeValue.value(
                primary: l1AmountData.appValue.formattedShort() ?? "",
                secondary: l1AmountData.currencyValue.flatMap { ValueFormatter.instance.formatShort(currencyValue: $0) } ?? "n/a".localized
            )
        }

        return (l2Value, l1Value, .value(primary: evmFeeData.gasLimit.description, secondary: nil))
    }

    func feeAmount(feeToken: Token, currency: Currency, feeTokenRate: Decimal?, loading: Bool, feeData: FeeData?) -> FeeSettings.FeeValue {
        guard !loading else {
            return .spinner
        }

        guard case let .bitcoin(sendInfo) = feeData,
              let amountData = sendInfo.amountData(feeToken: feeToken, currency: currency, feeTokenRate: feeTokenRate)
        else {
            return FeeSettings.FeeValue.none
        }

        return .value(
            primary: amountData.appValue.formattedShort() ?? "",
            secondary: amountData.currencyValue.flatMap { ValueFormatter.instance.formatShort(currencyValue: $0) } ?? "n/a".localized
        )
    }

    @ViewBuilder func row(title: String, feeValue: FeeSettings.FeeValue, infoDescription: InfoDescription) -> some View {
        Cell(
            middle: {
                MiddleTextIcon(text: title)
                    .modifier(Informed(infoDescription: infoDescription, horizontalPadding: 0))
            },
            right: {
                switch feeValue {
                case .spinner:
                    ProgressView().progressViewStyle(.circular)
                case .none:
                    RightMultiText(
                        subtitleSB: "n/a".localized
                    )
                case let .value(primary, secondary):
                    RightMultiText(
                        subtitleSB: primary,
                        description: secondary
                    )
                }
            }
        )
    }

    @ViewBuilder func headerRow(title: String, infoDescription: InfoDescription) -> some View {
        HStack(spacing: 0) {
            ThemeText(title, style: .subheadSB, colorStyle: .secondary)
                .modifier(Informed(infoDescription: infoDescription))

            Spacer()
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder func inputNumberWithSteps(placeholder: String = "", text: Binding<String>, cautionState: Binding<FieldCautionState>, onTap: @escaping (StepChangeButtonsViewDirection) -> Void) -> some View {
        InputTextRow(vertical: .margin8) {
            StepChangeButtonsView(content: {
                InputTextView(
                    placeholder: placeholder,
                    text: text
                )
                .font(.themeBody)
                .keyboardType(.numberPad)
                .autocorrectionDisabled()
            }, onTap: onTap)
        }
        .modifier(FieldCautionBorder(cautionState: cautionState))
    }
}
