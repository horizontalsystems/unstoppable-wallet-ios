import EvmKit
import Foundation
import MarketKit
import SwiftUI

struct MultiSwapApproveView: View {
    @StateObject private var viewModel: MultiSwapApproveViewModel
    @Binding private var isPresented: Bool
    private let onSuccess: () -> Void

    @State private var unlockPresented = false
    @Environment(\.dismiss) private var dismiss

    init(tokenIn: Token, amount: Decimal, spenderAddress: EvmKit.Address, isPresented: Binding<Bool>, onSuccess: @escaping () -> Void) {
        _viewModel = .init(wrappedValue: MultiSwapApproveViewModel(token: tokenIn, amount: amount, spenderAddress: spenderAddress))
        _isPresented = isPresented
        self.onSuccess = onSuccess
    }

    var body: some View {
        ThemeView {
            if let transactionData = viewModel.transactionData {
                BottomGradientWrapper {
                    VStack(spacing: .margin12) {
                        Text("swap.unlock.subtitle".localized)
                            .themeHeadline1()
                            .padding(.horizontal, .margin16)
                            .padding(.bottom, .margin12)

                        ListSection {
                            ClickableRow(action: {
                                viewModel.set(unlimitedAmount: false)
                            }) {
                                let coinValue = CoinValue(kind: .token(token: viewModel.token), value: viewModel.amount)
                                let amountString = ValueFormatter.instance.formatFull(coinValue: coinValue) ?? ""
                                row(text: amountString, selected: !viewModel.unlimitedAmount)
                            }
                            ClickableRow(action: {
                                viewModel.set(unlimitedAmount: true)
                            }) {
                                row(text: "swap.unlock.unlimited".localized, selected: viewModel.unlimitedAmount)
                            }
                        }

                        Text("swap.unlock.description".localized)
                            .themeSubhead2()
                            .padding(.horizontal, .margin16)

                        Spacer()
                    }
                    .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                } bottomContent: {
                    Button(action: {
                        unlockPresented = true
                    }) {
                        Text("button.unlock".localized)
                    }
                    .buttonStyle(PrimaryButtonStyle(style: .yellow))
                }

                NavigationLink(
                    isActive: $unlockPresented,
                    destination: {
                        SendConfirmationNewView(sendData: .evm(blockchainType: viewModel.token.blockchainType, transactionData: transactionData)) {
                            onSuccess()
                            isPresented = false
                        }
                    }
                ) {
                    EmptyView()
                }
            }
        }
        .navigationTitle("swap.unlock.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("button.cancel".localized) {
                    isPresented = false
                }
            }
        }
    }

    @ViewBuilder func row(text: String, selected: Bool) -> some View {
        HStack(spacing: .margin16) {
            Image("check_2_20")
                .themeIcon(color: .themeJacob)
                .opacity(selected ? 1 : 0)
                .frame(width: .iconSize20, height: .iconSize20, alignment: .center)
                .overlay(
                    RoundedRectangle(cornerRadius: .cornerRadius4, style: .continuous)
                        .stroke(Color.themeGray, lineWidth: .heightOneDp + .heightOnePixel)
                )

            Text(text).themeSubhead2(color: .themeLeah)
        }
    }
}
