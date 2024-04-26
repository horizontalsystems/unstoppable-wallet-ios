import MarketKit
import SwiftUI

struct BitcoinFeeSettingsView: View {
    @StateObject private var viewModel: BitcoinFeeSettingsViewModel
    @Binding private var feeData: FeeData?
    @Binding private var loading: Bool
    private var feeToken: Token
    private var currency: Currency
    @Binding private var feeTokenRate: Decimal?

    private var helper = FeeSettingsViewHelper()
    @Environment(\.presentationMode) private var presentationMode

    init(service: BitcoinTransactionService, blockchainType _: BlockchainType, feeData: Binding<FeeData?>, loading: Binding<Bool>, feeToken: Token, currency: Currency, feeTokenRate: Binding<Decimal?>) {
        _viewModel = .init(wrappedValue: BitcoinFeeSettingsViewModel(service: service))
        _feeData = feeData
        _loading = loading
        self.feeToken = feeToken
        self.currency = currency
        _feeTokenRate = feeTokenRate
    }

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                ListSection {
                    helper.row(
                        title: "fee_settings.network_fee".localized,
                        feeValue: helper.feeAmount(feeToken: feeToken, currency: currency, feeTokenRate: feeTokenRate, loading: loading, feeData: feeData),
                        description: .init(title: "fee_settings.network_fee".localized, description: "fee_settings.network_fee.info".localized)
                    )
                }

                VStack(spacing: 0) {
                    helper.headerRow(
                        title: "fee_settings.fee_rate".localized + " (Sat/Byte)".localized,
                        description: .init(
                            title: "fee-rate-description-cell".localized,
                            description: "fee_settings.fee_rate.description".localized
                        )
                    )
                    helper.inputNumberWithSteps(
                        placeholder: "",
                        text: $viewModel.satoshiPerByte,
                        cautionState: $viewModel.satoshiPerByteCautionState,
                        onTap: viewModel.stepChangesatoshiPerByte
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
        .animation(.default, value: viewModel.satoshiPerByte)
        .navigationTitle("fee_settings".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("button.reset".localized) {
                    viewModel.onReset()
                }.disabled(!viewModel.resetEnabled)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("button.done".localized) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
