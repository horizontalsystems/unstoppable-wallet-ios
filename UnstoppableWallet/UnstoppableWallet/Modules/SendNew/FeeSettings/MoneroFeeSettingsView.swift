import MarketKit
import MoneroKit
import SwiftUI

struct MoneroFeeSettingsView: View {
    @EnvironmentObject private var sendViewModel: SendViewModel
    @StateObject private var viewModel: MoneroFeeSettingsViewModel
    private var feeToken: Token

    private var helper = FeeSettingsViewHelper()
    @Environment(\.presentationMode) private var presentationMode

    init(service: MoneroTransactionService, feeToken: Token) {
        _viewModel = .init(wrappedValue: MoneroFeeSettingsViewModel(service: service))
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

                ListSection {
                    ListRow {
                        HStack(spacing: .margin8) {
                            Text("monero.priority".localized).textSubhead2()

                            Spacer()

                            Button(action: {
                                Coordinator.shared.present(type: .alert) { isPresented in
                                    OptionAlertView(
                                        title: "monero.priority".localized,
                                        viewItems: SendPriority.allCases.map { AlertViewItem(text: $0.description) },
                                        onSelect: { viewModel.set(priorityAtIndex: $0) },
                                        isPresented: isPresented
                                    )
                                }
                            }) {
                                HStack(spacing: .margin8) {
                                    Text(viewModel.priority).textCaption(color: .themeLeah)
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle(rightAccessory: .dropDown))
                        }
                    }
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
