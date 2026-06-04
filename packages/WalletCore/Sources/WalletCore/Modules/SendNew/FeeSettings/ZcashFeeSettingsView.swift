// import MarketKit
// import SwiftUI
//
// struct ZcashFeeSettingsView: View {
//    @StateObject private var viewModel: ZcashFeeSettingsViewModel
//    private let feeToken: Token
//    private let currency: Currency
//    private let feeTokenRate: Decimal?
//    private let helper = FeeSettingsViewHelper()
//
//    @Environment(\.presentationMode) private var presentationMode
//    @FocusState private var isFocused: Bool
//
//    init(service: ZcashTransactionService, fee: Decimal?, feeToken: Token, currency: Currency, feeTokenRate: Decimal?) {
//        _viewModel = .init(wrappedValue: ZcashFeeSettingsViewModel(service: service, fee: fee))
//        self.feeToken = feeToken
//        self.currency = currency
//        self.feeTokenRate = feeTokenRate
//    }
//
//    var body: some View {
//        ThemeNavigationStack {
//            ThemeView {
//                BottomGradientWrapper {
//                    ScrollView {
//                        VStack(spacing: .margin24) {
//                            ListSection {
//                                helper.row(
//                                    title: "fee_settings.network_fee".localized,
//                                    feeValue: helper.feeAmount(
//                                        fee: viewModel.fee,
//                                        feeToken: feeToken,
//                                        currency: currency,
//                                        feeTokenRate: feeTokenRate
//                                    ),
//                                    infoDescription: .init(title: "fee_settings.network_fee".localized, description: "fee_settings.network_fee.info".localized)
//                                )
//                                .frame(minHeight: 68)
//                            }
//
//                            VStack(spacing: 0) {
//                                helper.headerRow(
//                                    title: "fee_settings.zcash_marginal_fee".localized,
//                                    infoDescription: .init(
//                                        title: "fee_settings.zcash_marginal_fee".localized,
//                                        description: "fee_settings.zcash_marginal_fee.info".localized
//                                    )
//                                )
//
//                                helper.inputNumberWithSteps(
//                                    text: viewModel.marginalFeeValue,
//                                    cautionState: $viewModel.marginalFeeCautionState,
//                                    onTap: viewModel.stepChangeMarginalFee
//                                )
//                            }
//
//                            let cautions = viewModel.cautions
//                            if !cautions.isEmpty {
//                                VStack(spacing: .margin12) {
//                                    ForEach(cautions.indices, id: \.self) { index in
//                                        AlertCardView(caution: cautions[index])
//                                    }
//                                }
//                            }
//                        }
//                        .padding(EdgeInsets(top: 16, leading: 16, bottom: 32, trailing: 16))
//                    }
//                } bottomContent: {
//                    ThemeButton(text: "button.apply".localized) {
//                        viewModel.apply()
//                        presentationMode.wrappedValue.dismiss()
//                    }
//                    .disabled(!viewModel.applyEnabled)
//                }
//            }
//            .onTapGesture {
//                isFocused = false
//            }
//            .animation(.default, value: viewModel.marginalFeeCautionState)
//            .navigationTitle("fee_settings.title".localized)
//            .toolbar {
//                ToolbarItem(placement: .primaryAction) {
//                    Button(action: {
//                        viewModel.onReset()
//                    }) {
//                        Image("reset")
//                    }
//                    .disabled(!viewModel.resetEnabled)
//                }
//
//                ToolbarItem(placement: .cancellationAction) {
//                    Button(action: {
//                        presentationMode.wrappedValue.dismiss()
//                    }) {
//                        Image("close")
//                    }
//                }
//            }
//        }
//    }
// }
