import Foundation
import MarketKit
import SwiftUI

struct LegacyFeeSettingsView: View {
    @StateObject private var viewModel: LegacyFeeSettingsViewModel
    @Binding private var feeData: FeeData?
    @Binding private var loading: Bool
    private var feeToken: Token
    private var currency: Currency
    @Binding private var feeTokenRate: Decimal?

    private var helper = FeeSettingsViewHelper()
    @Environment(\.presentationMode) private var presentationMode

    init(service: EvmTransactionService, blockchainType: BlockchainType, feeData: Binding<FeeData?>, loading: Binding<Bool>, feeToken: Token, currency: Currency, feeTokenRate: Binding<Decimal?>) {
        _viewModel = .init(wrappedValue: LegacyFeeSettingsViewModel(service: service, feeViewItemFactory: FeeViewItemFactory(scale: blockchainType.feePriceScale)))
        _feeData = feeData
        _loading = loading
        self.feeToken = feeToken
        self.currency = currency
        _feeTokenRate = feeTokenRate
    }

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                let (l2FeeValue, l1FeeValue, gasLimitValue) = helper.feeAmount(
                    feeToken: feeToken, currency: currency, feeTokenRate: feeTokenRate, loading: loading,
                    feeData: feeData, gasPrice: viewModel.service.gasPrice
                )

                ListSection {
                    helper.row(
                        title: "fee_settings.network_fee".localized,
                        feeValue: l2FeeValue,
                        description: .init(title: "fee_settings.network_fee".localized, description: "fee_settings.network_fee.info".localized)
                    )
                    if let l1FeeValue {
                        helper.row(
                            title: "fee_settings.l1_fee".localized,
                            feeValue: l1FeeValue,
                            description: .init(title: "fee_settings.l1_fee".localized, description: "fee_settings.l1_fee.info".localized)
                        )
                    }
                    helper.row(
                        title: "fee_settings.gas_limit".localized,
                        feeValue: gasLimitValue,
                        description: .init(title: "fee_settings.gas_limit".localized, description: "fee_settings.gas_limit.info".localized)
                    )
                }

                VStack(spacing: 0) {
                    helper.headerRow(
                        title: "fee_settings.gas_price".localized,
                        description: .init(
                            title: "fee_settings.gas_price".localized,
                            description: "fee_settings.gas_price.info".localized
                        )
                    )
                    helper.inputNumberWithSteps(
                        placeholder: "",
                        text: $viewModel.gasPrice,
                        cautionState: $viewModel.gasPriceCautionState,
                        onTap: viewModel.stepChangeGasPrice
                    )
                }

                VStack(spacing: 0) {
                    helper.headerRow(
                        title: "evm_send_settings.nonce".localized,
                        description: .init(
                            title: "evm_send_settings.nonce".localized,
                            description: "evm_send_settings.nonce.info".localized
                        )
                    )
                    helper.inputNumberWithSteps(
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
        .animation(.default, value: viewModel.gasPriceCautionState)
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
}
