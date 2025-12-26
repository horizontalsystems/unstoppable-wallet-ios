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
                            feeData: sendViewModel.sendData?.feeData
                        ),
                        infoDescription: .init(title: "fee_settings.network_fee".localized, description: "fee_settings.network_fee.info".localized)
                    )
                    .frame(minHeight: 68)
                }

                ListSection {
                    Cell(
                        middle: {
                            MiddleTextIcon(text: "monero.priority".localized)
                        },
                        right: {
                            RightButtonText(text: viewModel.priority.description, icon: "arrow_s_down") {
                                Coordinator.shared.present(type: .alert) { isPresented in
                                    OptionAlertView(
                                        title: "monero.priority".localized,
                                        viewItems: SendPriority.allCases.map {
                                            AlertViewItem(text: $0.description, selected: $0 == viewModel.priority)
                                        },
                                        onSelect: { viewModel.set(priority: SendPriority.allCases[$0]) },
                                        isPresented: isPresented
                                    )
                                }
                            }
                        }
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
