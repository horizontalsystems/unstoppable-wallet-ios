import Foundation
import MarketKit
import SwiftUI

struct Eip1559FeeSettingsView: View {
    @ObservedObject var viewModel: Eip1559FeeSettingsViewModel
    @Binding var feeData: FeeData?
    @Binding var loading: Bool
    var feeToken: Token
    var currency: Currency
    @Binding var feeTokenRate: Decimal?

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                let (feeCoinValue, feeCurrencyValue) = FeeSettings.feeAmount(
                    feeToken: feeToken, currency: currency, feeTokenRate: feeTokenRate, loading: loading,
                    gasLimit: feeData?.gasLimit, gasPrice: viewModel.service.gasPrice
                )

                ListSection {
                    row(
                        viewItem: .init(
                            title: "fee_settings.network_fee".localized,
                            value: feeCoinValue,
                            subValue: feeCurrencyValue
                        ),
                        description: .init(title: "fee_settings.network_fee".localized, description: "fee_settings.network_fee.info".localized)
                    )
                    row(
                        viewItem: .init(
                            title: "fee_settings.gas_limit".localized,
                            value: feeData?.gasLimit?.description,
                            subValue: nil
                        ),
                        description: .init(title: "fee_settings.gas_limit".localized, description: "fee_settings.gas_limit.info".localized)
                    )
                    row(viewItem: .init(
                        title: "fee_settings.base_fee".localized,
                        value: viewModel.baseFee,
                        subValue: nil
                    ), description: .init(
                        title: "fee_settings.base_fee".localized,
                        description: "fee_settings.base_fee.info".localized
                    ))
                }

                VStack(spacing: 0) {
                    headerRow(
                        title: "fee_settings.max_fee_rate".localized,
                        description: .init(
                            title: "fee_settings.max_fee_rate".localized,
                            description: "fee_settings.max_fee_rate.info".localized
                        )
                    )
                    inputNumberWithSteps(
                        placeholder: "",
                        text: $viewModel.maxFee,
                        cautionState: $viewModel.maxFeeCautionState,
                        onTap: viewModel.stepChangeMaxFee
                    )
                }

                VStack(spacing: 0) {
                    headerRow(
                        title: "fee_settings.tips".localized,
                        description: .init(
                            title: "fee_settings.tips".localized,
                            description: "fee_settings.tips.info".localized
                        )
                    )
                    inputNumberWithSteps(
                        placeholder: "",
                        text: $viewModel.maxTips,
                        cautionState: $viewModel.maxTipsCautionState,
                        onTap: viewModel.stepChangeMaxTips
                    )
                }

                VStack(spacing: 0) {
                    headerRow(
                        title: "evm_send_settings.nonce".localized,
                        description: .init(
                            title: "evm_send_settings.nonce".localized,
                            description: "evm_send_settings.nonce.info".localized
                        )
                    )
                    inputNumberWithSteps(
                        placeholder: "",
                        text: $viewModel.nonce,
                        cautionState: $viewModel.nonceCautionState,
                        onTap: viewModel.stepChangeNonce
                    )
                }

                let cautions = viewModel.service.cautions
                if !cautions.isEmpty {
                    VStack(spacing: .margin12) {
                        ForEach(cautions.indices, id: \.self) { index in
                            HighlightedTextView(caution: cautions[index])
                        }
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .animation(.default, value: viewModel.maxFeeCautionState)
        .animation(.default, value: viewModel.maxTipsCautionState)
        .animation(.default, value: viewModel.nonceCautionState)
        .navigationTitle("fee_settings".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("button.reset".localized) {
                    viewModel.onReset()
                }.disabled(!viewModel.resetEnabled)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("button.done".localized) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }

    @ViewBuilder private func row(viewItem: FeeSettings.ViewItem, description: AlertView.InfoDescription) -> some View {
        HStack(spacing: .margin8) {
            Text(viewItem.title)
                .textSubhead2()
                .modifier(Informed(description: description))

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                if let value = viewItem.value {
                    Text(value).textSubhead1(color: .themeLeah)

                    if let subValue = viewItem.subValue {
                        Text(subValue).textSubhead2()
                    }
                } else {
                    ProgressView().progressViewStyle(.circular)
                }
            }
        }
        .padding(EdgeInsets(top: .margin12, leading: 0, bottom: .margin12, trailing: .margin16))
        .frame(height: .heightCell56)
    }

    @ViewBuilder private func headerRow(title: String, description: AlertView.InfoDescription) -> some View {
        Text(title)
            .textSubhead1()
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(Informed(description: description))
    }

    @ViewBuilder private func inputNumberWithSteps(placeholder: String = "", text: Binding<String>, cautionState: Binding<FieldCautionState>, onTap: @escaping (StepChangeButtonsViewDirection) -> Void) -> some View {
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
