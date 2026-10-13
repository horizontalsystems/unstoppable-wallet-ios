import MarketKit
import SwiftUI

struct SplitSwapRecipientsView: View {
    @ObservedObject var viewModel: SplitSwapViewModel
    let onNext: () -> Void

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                ScrollView {
                    VStack(spacing: 16) {
                        ThemeText("swap.private.recipients.description".localized, style: .subhead, colorStyle: .secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)

                        VStack(spacing: 12) {
                            ForEach(viewModel.recipients.indices, id: \.self) { index in
                                recipientCard(index: index)
                            }
                        }

                        SplitPercentSlider(
                            percent: Binding(
                                get: { viewModel.splitPercent },
                                set: { viewModel.set(splitPercent: $0) }
                            )
                        )
                        .padding(.top, 4)

                        if viewModel.hasDuplicateRecipients {
                            AlertCardView(
                                .init(
                                    title: "swap.private.duplicate_addresses.title".localized,
                                    text: "swap.private.duplicate_addresses.text".localized,
                                    type: .caution
                                )
                            )
                            .padding(.top, 16)
                        }
                    }
                    .padding(EdgeInsets(top: 12, leading: 16, bottom: 32, trailing: 16))
                }
            } bottomContent: {
                let state = viewModel.recipientsButtonState

                ThemeButton(text: state.title, spinner: state.showProgress, style: .primary) {
                    onNext()
                }
                .disabled(state.disabled)
            }
        }
        .navigationTitle("swap.private.recipients.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.editor)
        .onAppear {
            // Only a split change requotes here: no silent refresh timer under the user's hands
            viewModel.stopAutoQuoting()

            // e.g. back from a confirmation that failed, or the round interrupted by leaving the tab
            if !viewModel.requoting, viewModel.splitQuote?.percents != viewModel.percents {
                viewModel.syncQuotes()
            }
        }
    }

    @ViewBuilder private func recipientCard(index: Int) -> some View {
        ListSection {
            Cell(
                left: {
                    ThemeImage(contactName(index: index) != nil ? "user_filled" : "wallet_filled", size: 24, colorStyle: .secondary)
                },
                middle: {
                    HStack(spacing: 8) {
                        if let address = viewModel.recipients[index] {
                            if let contactName = contactName(index: index) {
                                VStack(alignment: .leading, spacing: 0) {
                                    ThemeText(contactName, style: .headline2, colorStyle: .primary)
                                        .lineLimit(1)
                                    ThemeText(address.address.shortened, style: .subhead, colorStyle: addressColorStyle(address: address, index: index, regular: .secondary))
                                        .lineLimit(1)
                                }
                            } else {
                                ThemeText(address.address.shortened, style: .headline2, colorStyle: addressColorStyle(address: address, index: index, regular: .primary))
                                    .lineLimit(1)
                            }
                        } else {
                            ThemeText("swap.private.address".localized(index + 1), style: .headline2, colorStyle: .primary)
                                .lineLimit(1)
                        }

                        ThemeImage("arrow_s_down", size: 20, colorStyle: .primary)
                    }
                },
                right: {
                    RightMultiText(
                        eyebrow: amountText(index: index),
                        subtitle: ComponentText(text: "\(viewModel.percents[index])%", colorStyle: .yellow)
                    )
                },
                action: {
                    presentAddressPicker(index: index)
                }
            )
        }
    }

    // A flagged address stays red; a repeat of an earlier recipient's address is yellow
    private func addressColorStyle(address: ResolvedAddress, index: Int, regular: ColorStyle) -> ColorStyle {
        if !address.issueTypes.isEmpty {
            return .red
        }

        return viewModel.isDuplicateRecipient(at: index) ? .yellow : regular
    }

    private func contactName(index: Int) -> String? {
        viewModel.contactNames.indices.contains(index) ? viewModel.contactNames[index] : nil
    }

    private func amountText(index: Int) -> ComponentText? {
        guard let tokenOut = viewModel.tokenOut, let amount = viewModel.outputAmount(at: index) else {
            return nil
        }

        let formatted = AppValue(token: tokenOut, value: amount).formattedShort() ?? amount.description
        let fresh = viewModel.splitQuote?.percents == viewModel.percents

        return ComponentText(text: formatted, colorStyle: fresh ? .primary : .secondary)
    }

    private func presentAddressPicker(index: Int) {
        guard let tokenOut = viewModel.tokenOut else {
            return
        }

        Coordinator.shared.present { isPresented in
            // fromAddress is the sender's own address, used to flag a send-to-self; the swap output
            // may go to any address, the account's own included
            SendAddressViewWrapper(
                token: tokenOut,
                fromAddress: nil,
                address: viewModel.recipients[index]?.address,
                isPresented: isPresented
            ) { resolved in
                viewModel.set(recipient: resolved, index: index)
            }
        }
    }
}

struct SplitSwapSendDestinationView: View {
    @ObservedObject var viewModel: SplitSwapViewModel
    let onFinish: () -> Void

    var body: some View {
        if let sendData = viewModel.splitSendData {
            MultiSwapSendView(sendData: sendData, onFinish: onFinish)
        }
    }
}
