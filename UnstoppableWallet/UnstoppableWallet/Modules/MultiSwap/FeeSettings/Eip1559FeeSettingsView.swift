import Foundation
import SwiftUI

struct Eip1559FeeSettingsView: View {
    @ObservedObject var viewModel: Eip1559FeeSettingsViewModel

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                ListSection {
                    row(viewItem: ViewItem(
                        title: Section.fee.title,
                        value: "$0.98",
                        subValue: "12 ETH"
                    ), description: .init(
                        title: Section.fee.title,
                        description: Section.fee.info
                    ))

                    row(viewItem: ViewItem(
                        title: Section.gasLimit.title,
                        value: "12,412",
                        subValue: nil
                    ), description: .init(
                        title: Section.gasLimit.title,
                        description: Section.gasLimit.info
                    ))

                    row(viewItem: ViewItem(
                        title: Section.baseFee.title,
                        value: "46 GWei",
                        subValue: nil
                    ), description: .init(
                        title: Section.baseFee.title,
                        description: Section.baseFee.info
                    ))
                }

                VStack(spacing: 0) {
                    headerRow(
                        title: Section.maxFeeRate.title,
                        description: .init(
                            title: Section.maxFeeRate.title,
                            description: Section.maxFeeRate.info)
                    )
                    inputNumberWithSteps(
                            placeholder: "Def_Value",
                            text: $viewModel.maxFeeRate,
                            cautionState: $viewModel.maxFeeRateCautionState,
                            onTap: viewModel.stepChangeMaxFeeRate
                    )
                }

                VStack(spacing: 0) {
                    headerRow(
                        title: Section.maxPriority.title,
                        description: .init(
                            title: Section.maxPriority.title,
                            description: Section.maxPriority.info)
                    )
                    inputNumberWithSteps(
                            placeholder: "Def_Value",
                            text: $viewModel.maxFee,
                            cautionState: $viewModel.maxFeeCautionState,
                            onTap: viewModel.stepChangeMaxFee
                    )
                }

                VStack(spacing: 0) {
                    headerRow(
                        title: Section.nonce.title,
                        description: .init(
                            title: Section.nonce.title,
                            description: Section.nonce.info)
                    )
                    inputNumberWithSteps(
                            placeholder: "Def_Value",
                            text: $viewModel.nonce,
                            cautionState: $viewModel.nonceCautionState,
                            onTap: viewModel.stepChangeNonce
                    )
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .animation(.default, value: viewModel.maxFeeRateCautionState)
        .animation(.default, value: viewModel.maxFeeCautionState)
        .animation(.default, value: viewModel.nonceCautionState)
        .navigationTitle("fee_settings.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("button.reset".localized.uppercased()) {
                viewModel.onReset()
            }.disabled(!viewModel.resetEnabled)
        }
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

    @ViewBuilder private func headerRow(title: String, description: AlertView.InfoDescription) -> some View {
        HStack(spacing: .margin8) {
            Text(title).textSubhead1()
            Spacer()
            EmptyView().modifier(Informed(description: description))
        }
        .padding(EdgeInsets(top: 0, leading: .margin16, bottom: 0, trailing: 0))
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

    enum Section: Int {
        case fee, gasLimit, baseFee
        case maxFeeRate, maxPriority, nonce

        var title: String {
            switch self {
            case .fee: return "fee_settings.network_fee".localized
            case .gasLimit: return "fee_settings.gas_limit".localized
            case .baseFee: return "fee_settings.base_fee".localized
            case .maxFeeRate: return "fee_settings.max_fee_rate".localized
            case .maxPriority: return "fee_settings.tips".localized
            case .nonce: return "evm_send_settings.nonce".localized
            }
        }

        var info: String {
            switch self {
            case .fee: return "fee_settings.network_fee.info".localized
            case .gasLimit: return "fee_settings.gas_limit.info".localized
            case .baseFee: return "fee_settings.base_fee.info".localized
            case .maxFeeRate: return "fee_settings.max_fee_rate.info".localized
            case .maxPriority: return "fee_settings.tips.info".localized
            case .nonce: return "evm_send_settings.nonce.info".localized
            }
        }
    }
}
