import Foundation
import MarketKit
import SwiftUI

struct LegacyFeeSettingsView: View {
    @StateObject private var viewModel: LegacyFeeSettingsViewModel
    private let evmFeeData: EvmFeeData
    private let feeToken: Token
    private let currency: Currency
    private let feeTokenRate: Decimal?
    private let helper = FeeSettingsViewHelper()

    @Environment(\.presentationMode) private var presentationMode
    @FocusState private var isFocused: Bool

    init(service: EvmTransactionService, evmFeeData: EvmFeeData, feeToken: Token, currency: Currency, feeTokenRate: Decimal?) {
        _viewModel = .init(wrappedValue: LegacyFeeSettingsViewModel(service: service, feeViewItemFactory: FeeViewItemFactory(scale: feeToken.blockchainType.feePriceScale)))
        self.evmFeeData = evmFeeData
        self.feeToken = feeToken
        self.currency = currency
        self.feeTokenRate = feeTokenRate
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                BottomGradientWrapper {
                    ScrollView {
                        VStack(spacing: .margin24) {
                            let (l2FeeValue, l1FeeValue, gasLimitValue) = helper.feeAmount(
                                gasPrice: viewModel.gasPrice,
                                evmFeeData: evmFeeData,
                                feeToken: feeToken,
                                currency: currency,
                                feeTokenRate: feeTokenRate
                            )

                            ListSection {
                                helper.row(
                                    title: "fee_settings.network_fee".localized,
                                    feeValue: l2FeeValue,
                                    infoDescription: .init(title: "fee_settings.network_fee".localized, description: "fee_settings.network_fee.info".localized)
                                )
                                .frame(minHeight: 68)

                                if let l1FeeValue {
                                    helper.row(
                                        title: "fee_settings.l1_fee".localized,
                                        feeValue: l1FeeValue,
                                        infoDescription: .init(title: "fee_settings.l1_fee".localized, description: "fee_settings.l1_fee.info".localized)
                                    )
                                }

                                helper.row(
                                    title: "fee_settings.gas_limit".localized,
                                    feeValue: gasLimitValue,
                                    infoDescription: .init(title: "fee_settings.gas_limit".localized, description: "fee_settings.gas_limit.info".localized)
                                )
                            }

                            VStack(spacing: 0) {
                                helper.headerRow(
                                    title: "fee_settings.gas_price".localized + " (Gwei)",
                                    infoDescription: .init(
                                        title: "fee_settings.gas_price".localized,
                                        description: "fee_settings.gas_price.info".localized
                                    )
                                )

                                helper.inputNumberWithSteps(
                                    placeholder: "",
                                    text: viewModel.gasPriceValue,
                                    cautionState: $viewModel.gasPriceCautionState,
                                    onTap: viewModel.stepChangeGasPrice
                                )
                                .focused($isFocused)
                            }

                            let cautions = viewModel.cautions
                            if !cautions.isEmpty {
                                VStack(spacing: .margin12) {
                                    ForEach(cautions.indices, id: \.self) { index in
                                        AlertCardView(caution: cautions[index])
                                    }
                                }
                            }
                        }
                        .padding(EdgeInsets(top: 16, leading: 16, bottom: 32, trailing: 16))
                    }
                } bottomContent: {
                    ThemeButton(text: "button.apply".localized) {
                        viewModel.apply()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(!viewModel.applyEnabled)
                }
            }
            .onTapGesture {
                isFocused = false
            }
            .animation(.default, value: viewModel.gasPriceCautionState)
            .navigationTitle("fee_settings.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("button.reset".localized) {
                        viewModel.onReset()
                    }
                    .foregroundStyle(viewModel.resetEnabled ? Color.themeJacob : Color.themeGray)
                    .disabled(!viewModel.resetEnabled)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("button.cancel".localized) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
