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
            primary: ValueFormatter.instance.formatShort(coinValue: l2AmountData.coinValue) ?? "",
            secondary: l2AmountData.currencyValue.flatMap { ValueFormatter.instance.formatShort(currencyValue: $0) } ?? "n/a".localized
        )

        var l1Value: FeeSettings.FeeValue?

        if let l1AmountData = evmFeeData.l1AmountData(feeToken: feeToken, currency: currency, feeTokenRate: feeTokenRate) {
            l1Value = FeeSettings.FeeValue.value(
                primary: ValueFormatter.instance.formatShort(coinValue: l1AmountData.coinValue) ?? "",
                secondary: l1AmountData.currencyValue.flatMap { ValueFormatter.instance.formatShort(currencyValue: $0) } ?? "n/a".localized
            )
        }

        return (l2Value, l1Value, .value(primary: evmFeeData.gasLimit.description, secondary: nil))
    }

    @ViewBuilder func row(title: String, feeValue: FeeSettings.FeeValue, description: AlertView.InfoDescription) -> some View {
        HStack(spacing: .margin8) {
            Text(title)
                .textSubhead2()
                .modifier(Informed(description: description))

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                switch feeValue {
                case .spinner: ProgressView().progressViewStyle(.circular)
                case .none: Text("n/a".localized).textSubhead1(color: .themeLeah)
                case let .value(primary, secondary):
                    Text(primary).textSubhead1(color: .themeLeah)

                    if let secondary {
                        Text(secondary).textSubhead2()
                    }
                }
            }
        }
        .padding(EdgeInsets(top: .margin12, leading: 0, bottom: .margin12, trailing: .margin16))
        .frame(height: .heightCell56)
    }

    @ViewBuilder func headerRow(title: String, description: AlertView.InfoDescription) -> some View {
        Text(title)
            .textSubhead1()
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(Informed(description: description))
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
