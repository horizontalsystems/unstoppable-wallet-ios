import MarketKit
import SwiftUI

struct BitcoinFeeSettingsView: View {
    @EnvironmentObject private var sendViewModel: SendViewModel
    @StateObject private var viewModel: BitcoinFeeSettingsViewModel
    private var feeToken: Token

    private var helper = FeeSettingsViewHelper()
    @Environment(\.presentationMode) private var presentationMode

    init(service: BitcoinTransactionService, feeToken: Token) {
        _viewModel = .init(wrappedValue: BitcoinFeeSettingsViewModel(service: service))
        self.feeToken = feeToken
    }

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                ListSection {
                    helper.row(
                        title: "fee_settings.network_fee".localized,
                        feeValue: helper.feeAmount(
                            feeToken: feeToken,
                            currency: sendViewModel.currency,
                            feeTokenRate: sendViewModel.rates[feeToken.coin.uid],
                            loading: sendViewModel.state.isSyncing,
                            feeData: sendViewModel.sendData?.feeData
                        ),
                        infoDescription: .init(title: "fee_settings.network_fee".localized, description: "fee_settings.network_fee.info".localized)
                    )
                    .frame(minHeight: 68)
                }

                VStack(spacing: 0) {
                    helper.headerRow(
                        title: "fee_settings.fee_rate".localized + " (Sat/Byte)".localized,
                        infoDescription: .init(
                            title: "send.fee_info.title".localized,
                            description: "send.fee_info.description".localized
                        )
                    )

                    helper.inputNumberWithSteps(
                        placeholder: "",
                        text: viewModel.satoshiPerByte,
                        cautionState: $viewModel.satoshiPerByteCautionState,
                        onTap: viewModel.stepChangesatoshiPerByte
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
        .animation(.default, value: viewModel.satoshiPerByteCautionState)
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
