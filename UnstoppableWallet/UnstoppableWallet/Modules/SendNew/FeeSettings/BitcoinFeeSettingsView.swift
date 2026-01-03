import BitcoinCore
import MarketKit
import SwiftUI

struct BitcoinFeeSettingsView: View {
    @StateObject private var viewModel: BitcoinFeeSettingsViewModel
    private let feeToken: Token
    private let currency: Currency
    private let feeTokenRate: Decimal?
    private let helper = FeeSettingsViewHelper()

    @Environment(\.presentationMode) private var presentationMode
    @FocusState private var isFocused: Bool

    init(service: BitcoinTransactionService, params: SendParameters, feeToken: Token, currency: Currency, feeTokenRate: Decimal?) {
        _viewModel = .init(wrappedValue: BitcoinFeeSettingsViewModel(service: service, params: params))
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
                            ListSection {
                                helper.row(
                                    title: "fee_settings.network_fee".localized,
                                    feeValue: helper.feeAmount(
                                        fee: viewModel.fee,
                                        feeToken: feeToken,
                                        currency: currency,
                                        feeTokenRate: feeTokenRate,
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
                                    text: viewModel.satoshiPerByteValue,
                                    cautionState: $viewModel.satoshiPerByteCautionState,
                                    onTap: viewModel.stepChangesatoshiPerByte
                                )
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
                    Button("button.cancel".localized) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
