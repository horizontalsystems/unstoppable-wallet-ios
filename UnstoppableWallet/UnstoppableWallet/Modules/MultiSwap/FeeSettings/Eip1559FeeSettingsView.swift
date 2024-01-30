import Foundation
import MarketKit
import SwiftUI

struct Eip1559FeeSettingsView: View {
    @ObservedObject var viewModel: Eip1559FeeSettingsViewModel
    @Environment(\.presentationMode) private var presentationMode

    init(service: EvmMultiSwapTransactionService, feeViewItemFactory: FeeViewItemFactory) {
        viewModel = Eip1559FeeSettingsViewModel(service: service, feeViewItemFactory: feeViewItemFactory)
    }

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                ListSection {
                    row(viewItem: ViewItem(
                        title: Section.baseFee.title,
                        value: viewModel.baseFee,
                        subValue: nil
                    ), description: .init(
                        title: Section.baseFee.title,
                        description: Section.baseFee.info
                    ))
                }

                VStack(spacing: 0) {
                    headerRow(
                        title: Section.maxFee.title,
                        description: .init(
                            title: Section.maxFee.title,
                            description: Section.maxFee.info
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
                        title: Section.maxTips.title,
                        description: .init(
                            title: Section.maxTips.title,
                            description: Section.maxTips.info
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
                        title: Section.nonce.title,
                        description: .init(
                            title: Section.nonce.title,
                            description: Section.nonce.info
                        )
                    )
                    inputNumberWithSteps(
                        placeholder: "",
                        text: $viewModel.nonce,
                        cautionState: $viewModel.nonceCautionState,
                        onTap: viewModel.stepChangeNonce
                    )
                }

                if let caution = viewModel.cautionState.caution {
                    VStack(spacing: 32) {
                        HighlightedTitledTextView(caution: caution)
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
        Text(title)
            .textSubhead1()
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(Informed(description: description))
    }

    @ViewBuilder private func inputNumberWithSteps(placeholder: String = "", text: Binding<String>, cautionState: Binding<FieldCautionState>, onTap: @escaping (StepChangeButtonsViewDirection) -> ()) -> some View {
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

extension Eip1559FeeSettingsView {
    struct ViewItem {
        let title: String
        let value: String
        let subValue: String?
    }

    enum Section: Int {
        case baseFee, maxFee, maxTips, nonce

        var title: String {
            switch self {
            case .baseFee: return "fee_settings.base_fee".localized
            case .maxFee: return "fee_settings.max_fee_rate".localized
            case .maxTips: return "fee_settings.tips".localized
            case .nonce: return "evm_send_settings.nonce".localized
            }
        }

        var info: String {
            switch self {
            case .baseFee: return "fee_settings.base_fee.info".localized
            case .maxFee: return "fee_settings.max_fee_rate.info".localized
            case .maxTips: return "fee_settings.tips.info".localized
            case .nonce: return "evm_send_settings.nonce.info".localized
            }
        }
    }
}
