import MarketKit
import SwiftUI

struct BitcoinFeeSettingsView: View {
    @StateObject private var viewModel: BitcoinFeeSettingsViewModel
    @Binding private var feeData: FeeData?
    @Binding private var loading: Bool
    private var feeToken: Token
    private var currency: Currency
    @Binding private var feeTokenRate: Decimal?
    @State private var feeRateInfoPresented: Bool = false

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
                    Button(action: {
                        feeRateInfoPresented = true
                    }, label: {
                        HStack(spacing: .margin8) {
                            HStack(spacing: .margin8) {
                                Text("fee_settings.fee_rate".localized + " (Sat/Byte)".localized).textSubhead1()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Image("circle_information_20").themeIcon()
                            }
                            .padding(EdgeInsets(top: 5.5, leading: .margin16, bottom: 5.5, trailing: .margin16))
                        }
                    })

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
        .sheet(isPresented: $feeRateInfoPresented) {
            InfoView(
                items: [
                    .header1(text: "send.fee_info.title".localized),
                    .text(text: "send.fee_info.description".localized),
                ],
                isPresented: $feeRateInfoPresented
            )
        }
    }
}
