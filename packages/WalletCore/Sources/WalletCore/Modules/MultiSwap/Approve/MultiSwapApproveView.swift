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

    init(tokenIn: Token, amount: Decimal, spenderAddress: Address, isPresented: Binding<Bool>, onSuccess: @escaping () -> Void) {
        _viewModel = .init(wrappedValue: MultiSwapApproveViewModel(token: tokenIn, amount: amount, spenderAddress: spenderAddress))
        _isPresented = isPresented
        self.onSuccess = onSuccess
    }

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                ScrollView {
                    VStack(spacing: .margin12) {
                        ListSection {
                            let appValue = AppValue(token: viewModel.token, value: viewModel.amount)
                            let amountString = appValue.formattedFull() ?? ""

                            row(text: amountString, selected: !viewModel.unlimitedAmount) {
                                viewModel.set(unlimitedAmount: false)
                            }
                            row(text: "swap.unlock.unlimited".localized, selected: viewModel.unlimitedAmount) {
                                viewModel.set(unlimitedAmount: true)
                            }
                        }

                        Text("swap.unlock.description".localized)
                            .themeSubhead2()
                            .padding(.horizontal, .margin16)

                        Spacer()
                    }
                    .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                }
            } bottomContent: {
                ThemeButton(text: "swap.approve".localized) {
                    unlockPresented = true
                }
            }
        }
        .navigationTitle("swap.unlock.title".localized)
        .navigationDestination(isPresented: $unlockPresented) {
            if let sendData = viewModel.sendData {
                RegularSendView(sendData: sendData) {
                    onSuccess()
                    isPresented = false
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
                    isPresented = false
                }) {
                    Image("close")
                }
            }
        }
    }

    @ViewBuilder private func row(text: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Cell(
            left: { CheckBoxUiView(checked: .init(get: { selected }, set: { _ in })) },
            middle: { ThemeText(text, style: .subhead, colorStyle: .primary) },
            action: action
        )
    }
}
