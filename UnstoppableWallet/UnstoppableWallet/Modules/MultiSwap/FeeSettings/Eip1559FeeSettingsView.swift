import Foundation
import SwiftUI

struct Eip1559FeeSettingsView: View {
    @ObservedObject var viewModel: Eip1559FeeSettingsViewModel

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                ListSection {
                    row(viewItem: ViewItem(
                        title: InfoType.fee.title,
                        value: "$0.98",
                        subValue: "12 ETH"
                    ), description: .init(
                        title: InfoType.fee.title,
                        description: InfoType.fee.info
                    ))

                    row(viewItem: ViewItem(
                        title: InfoType.gasLimit.title,
                        value: "12,412",
                        subValue: nil
                    ), description: .init(
                        title: InfoType.gasLimit.title,
                        description: InfoType.gasLimit.info
                    ))

                    row(viewItem: ViewItem(
                        title: InfoType.baseFee.title,
                        value: "46 GWei",
                        subValue: nil
                    ), description: .init(
                        title: InfoType.baseFee.title,
                        description: InfoType.baseFee.info
                    ))
                }

                inputNumberWithSteps(
                    placeholder: "Def_Value",
                    text: $viewModel.maxFeeRate,
                    cautionState: $viewModel.maxFeeRateCautionState,
                    onTap: viewModel.stepChangeMaxFeeRate
                )

                inputNumberWithSteps(
                    placeholder: "Def_Value",
                    text: $viewModel.maxFee,
                    cautionState: $viewModel.maxFeeCautionState,
                    onTap: viewModel.stepChangeMaxFeeRate
                )
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .animation(.default, value: viewModel.maxFeeRateCautionState)
        .animation(.default, value: viewModel.maxFeeCautionState)
        .navigationTitle("fee_settings.title".localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private func row(viewItem: ViewItem, description: AlertView.InfoDescription) -> some View {
        HStack(spacing: .margin8) {
            Text(viewItem.title)
                .textSubhead2()
                .modifier(Informed(description: description))

            Spacer()

            VStack(spacing: 1) {
                Text(viewItem.value).textSubhead1(color: .themeLeah)

                if let subValue = viewItem.subValue {
                    Text(subValue).textSubhead2()
                }
            }
        }
        .padding(EdgeInsets(top: .margin12, leading: 0, bottom: .margin12, trailing: .margin16))
        .frame(minHeight: .heightCell56)
    }

    @ViewBuilder private func inputNumberWithSteps(placeholder: String = "", text: Binding<String>, cautionState: Binding<CautionState>, onTap: @escaping (StepChangeButtonsViewDirection) -> ()) -> some View {
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
        .modifier(CautionBorder(cautionState: cautionState))
        .modifier(CautionPrompt(cautionState: cautionState))
    }
}

extension Eip1559FeeSettingsView {
    struct ViewItem {
        let title: String
        let value: String
        let subValue: String?
    }

    enum InfoType: Int {
        case fee, gasLimit, baseFee

        var title: String {
            switch self {
            case .fee: return "fee_settings.network_fee".localized
            case .gasLimit: return "fee_settings.gas_limit".localized
            case .baseFee: return "fee_settings.base_fee".localized
            }
        }

        var info: String {
            switch self {
            case .fee: return "fee_settings.network_fee.info".localized
            case .gasLimit: return "fee_settings.gas_limit.info".localized
            case .baseFee: return "fee_settings.base_fee.info".localized
            }
        }
    }
}
