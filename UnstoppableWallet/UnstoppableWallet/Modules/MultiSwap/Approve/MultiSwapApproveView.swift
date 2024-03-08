import EvmKit
import Foundation
import MarketKit
import SwiftUI

struct MultiSwapApproveView: View {
    @StateObject private var viewModel: MultiSwapApproveViewModel
    private var isPresented: Binding<Bool>

    @State private var unlockPresented = false
    @Environment(\.dismiss) private var dismiss

    init(tokenIn: Token, amount: Decimal, spenderAddress: EvmKit.Address, isPresented: Binding<Bool>) {
        _viewModel = .init(wrappedValue: MultiSwapApproveViewModel(token: tokenIn, amount: amount, spenderAddress: spenderAddress))
        self.isPresented = isPresented
    }

    var body: some View {
        ThemeView {
            if let transactionData = viewModel.transactionData {
                BottomGradientWrapper {
                    VStack(spacing: .margin32) {
                        VStack(spacing: .margin24) {
                            Text("Allow access to the following amount".localized)
                                .themeHeadline1()
                                .padding(.horizontal, .margin16)

                            Text("You should grant permission to a smart contract to swap given token on your behalf. This permission sets amount that can be used by a smart contract. It doesn't affect your balance but requires a small fee to execute approval transaction.\n\nWhile it may be done on demand before each trade, it's cheaper to approve higher amount in advance for future trades.")
                                .themeSubhead2()
                                .padding(.horizontal, .margin16)
                        }

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
                                row(text: "Unlimited", selected: viewModel.unlimitedAmount)
                            }
                        }

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
                        SendConfirmationNewView(
                            sendData: .evm(blockchainType: viewModel.token.blockchainType, transactionData: transactionData),
                            isParentPresented: isPresented
                        )
                    }
                ) {
                    EmptyView()
                }
            }
        }
        .navigationTitle("Unlock Access")
        .navigationBarTitleDisplayMode(.inline)
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