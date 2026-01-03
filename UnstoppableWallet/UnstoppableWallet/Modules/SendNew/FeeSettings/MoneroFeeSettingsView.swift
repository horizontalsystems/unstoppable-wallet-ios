import MarketKit
import MoneroKit
import SwiftUI

struct MoneroFeeSettingsView: View {
    @StateObject private var viewModel: MoneroFeeSettingsViewModel
    private var feeToken: Token
    private let currency: Currency
    private let feeTokenRate: Decimal?
    private var helper = FeeSettingsViewHelper()

    @Environment(\.presentationMode) private var presentationMode

    init(service: MoneroTransactionService, amount: MoneroSendAmount, address: String, feeToken: Token, currency: Currency, feeTokenRate: Decimal?) {
        _viewModel = .init(wrappedValue: MoneroFeeSettingsViewModel(service: service, amount: amount, address: address))
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
                                                    onSelect: { viewModel.priority = SendPriority.allCases[$0] },
                                                    isPresented: isPresented
                                                )
                                            }
                                        }
                                    }
                                )
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
