import Foundation
import MarketKit
import SwiftUI

struct Eip1559FeeSettingsView: View {
    @EnvironmentObject private var sendViewModel: SendViewModel
    @StateObject private var viewModel: Eip1559FeeSettingsViewModel
    private var feeToken: Token

    private var helper = FeeSettingsViewHelper()
    @Environment(\.presentationMode) private var presentationMode

    init(service: EvmTransactionService, blockchainType: BlockchainType, feeToken: Token) {
        _viewModel = .init(wrappedValue: Eip1559FeeSettingsViewModel(service: service, feeViewItemFactory: FeeViewItemFactory(scale: blockchainType.feePriceScale)))
        self.feeToken = feeToken
    }

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                let (l2FeeValue, l1FeeValue, gasLimitValue) = helper.feeAmount(
                    feeToken: feeToken,
                    currency: sendViewModel.currency,
                    feeTokenRate: sendViewModel.rates[feeToken.coin.uid],
                    loading: sendViewModel.state.isSyncing,
                    feeData: sendViewModel.sendData?.feeData,
                    gasPrice: viewModel.service.gasPrice
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

                    helper.row(
                        title: "fee_settings.base_fee".localized,
                        feeValue: viewModel.baseFee.map { .value(primary: $0, secondary: nil) } ?? .none,
                        infoDescription: .init(
                            title: "fee_settings.base_fee".localized,
                            description: "fee_settings.base_fee.info".localized
                        )
                    )
                }

                VStack(spacing: 0) {
                    helper.headerRow(
                        title: "fee_settings.max_fee_rate".localized + " (Gwei)",
                        infoDescription: .init(
                            title: "fee_settings.max_fee_rate".localized,
                            description: "fee_settings.max_fee_rate.info".localized
                        )
                    )

                    helper.inputNumberWithSteps(
                        placeholder: "",
                        text: viewModel.maxFee,
                        cautionState: $viewModel.maxFeeCautionState,
                        onTap: viewModel.stepChangeMaxFee
                    )
                }

                VStack(spacing: 0) {
                    helper.headerRow(
                        title: "fee_settings.tips".localized + " (Gwei)",
                        infoDescription: .init(
                            title: "fee_settings.tips".localized,
                            description: "fee_settings.tips.info".localized
                        )
                    )

                    helper.inputNumberWithSteps(
                        placeholder: "",
                        text: viewModel.maxTips,
                        cautionState: $viewModel.maxTipsCautionState,
                        onTap: viewModel.stepChangeMaxTips
                    )
                }

                let cautions = viewModel.service.cautions
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
        .animation(.default, value: viewModel.maxFeeCautionState)
        .animation(.default, value: viewModel.maxTipsCautionState)
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
                Button("button.close".localized) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
