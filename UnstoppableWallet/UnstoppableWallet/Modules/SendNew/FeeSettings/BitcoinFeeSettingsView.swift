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
                            feeData: sendViewModel.state.data?.feeData
                        ),
                        infoDescription: .init(title: "fee_settings.network_fee".localized, description: "fee_settings.network_fee.info".localized)
                    )
                }

                VStack(spacing: 0) {
                    Button(action: {
                        Coordinator.shared.present { isPresented in
                            InfoView(
                                items: [
                                    .header1(text: "send.fee_info.title".localized),
                                    .text(text: "send.fee_info.description".localized),
                                ],
                                isPresented: isPresented
                            )
                        }
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
                }
                .foregroundStyle(viewModel.resetEnabled ? Color.themeJacob : Color.themeGray)
                .disabled(!viewModel.resetEnabled)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("button.done".localized) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
