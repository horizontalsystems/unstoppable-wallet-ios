import SwiftUI

/// The form shared by the Standard, Private and Cross Pay tabs of PreSendView: balance, amount/fiat input,
/// address, tab-specific fields, cautions, a footer (info cards) and the Next button.
struct PreSendFormView<Fields: View, Footer: View>: View {
    @ObservedObject var viewModel: BasePreSendViewModel
    let addressVisible: Bool

    @Binding var path: NavigationPath
    @Binding var isPresented: Bool

    /// When set, the input's token selector is tappable (the amount is in a user-selected token).
    let onSelectToken: (() -> Void)?

    let fields: (FocusState<PreSendFocusField?>.Binding) -> Fields
    let footer: () -> Footer

    @FocusState private var focusField: PreSendFocusField?

    init(
        viewModel: BasePreSendViewModel,
        addressVisible: Bool,
        path: Binding<NavigationPath>,
        isPresented: Binding<Bool>,
        onSelectToken: (() -> Void)? = nil,
        @ViewBuilder fields: @escaping (FocusState<PreSendFocusField?>.Binding) -> Fields,
        @ViewBuilder footer: @escaping () -> Footer
    ) {
        self.viewModel = viewModel
        self.addressVisible = addressVisible
        _path = path
        _isPresented = isPresented
        self.onSelectToken = onSelectToken
        self.fields = fields
        self.footer = footer
    }

    var body: some View {
        BottomGradientWrapper(gradientColor: .themeLawrence) {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 0) {
                        AvailableBalanceView(
                            balance: viewModel.availableBalance,
                            token: viewModel.token,
                            allAvailable: viewModel.maxAmountEnabled,
                            currentValue: viewModel.amount,
                            onSelect: { percent in
                                viewModel.setAmountIn(percent: percent)
                                focusField = nil
                            },
                            onClear: {
                                viewModel.clearAmountIn()
                            },
                            percents: viewModel.balancePercents
                        )
                        .padding(.top, 16)
                        .padding(.horizontal, 16)

                        inputView()
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 24)

                        if addressVisible {
                            inputSeparatorView()

                            Button(action: {
                                presentAddressPicker()
                            }) {
                                addressView()
                                    .padding(.horizontal, 16)
                                    .frame(height: 89)
                            }
                        }

                        Color.themeBlade.frame(height: .heightOnePixel)

                        fields($focusField)

                        if !viewModel.cautions.isEmpty {
                            cautionsView()
                        }

                        footer()
                    }
                }
                .padding(.bottom, 32)
            }
            .onTapGesture {
                focusField = nil
            }
        } bottomContent: {
            buttonView()
        }
        .animation(.easeOut(duration: 0.25), value: focusField != nil)
    }

    private func inputView() -> some View {
        SendInputView(
            token: viewModel.inputToken,
            amountDecimals: viewModel.inputDecimals,
            amountString: $viewModel.amountString,
            fiatAmountString: $viewModel.fiatAmountString,
            coinPrice: viewModel.coinPrice,
            currency: viewModel.currency,
            focusedField: $focusField,
            amountField: .amount,
            fiatField: .fiatAmount,
            onSelectToken: onSelectToken
        )
    }

    private func inputSeparatorView() -> some View {
        Color.themeBlade.frame(height: .heightOnePixel)
            .overlay {
                ThemeImage("arrow_m_down", size: 20)
                    .padding(6)
                    .background(Color.themeLawrence)
            }
    }

    private func addressView() -> some View {
        HStack(spacing: 16) {
            // a 32 glyph centred in the 40 column of the token icon above, as on Android
            ThemeImage(viewModel.contactName != nil ? "user_filled" : "wallet_filled", size: 32)
                .frame(width: 40, height: 40)

            HStack(spacing: 8) {
                if let address = viewModel.resolvedAddress {
                    if let contactName = viewModel.contactName {
                        VStack(alignment: .leading, spacing: 0) {
                            ThemeText(contactName, style: .headline1)
                                .lineLimit(1)
                            ThemeText(address.address.shortened, style: .body, colorStyle: address.issueTypes.isEmpty ? .secondary : .red)
                                .lineLimit(1)
                        }
                    } else {
                        ThemeText(address.address, style: .headline1, colorStyle: address.issueTypes.isEmpty ? .primary : .red)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }
                } else {
                    ThemeText("send.address_placeholder".localized, style: .headline1, colorStyle: .primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }

                ThemeImage("arrow_s_down", size: 20, colorStyle: .primary)
            }

            Spacer()
        }
    }

    @ViewBuilder private func buttonView() -> some View {
        let state = viewModel.buttonState

        ThemeButton(text: state.title, spinner: state.showProgress, progress: state.progress, style: state.style) {
            // the wallet's own step comes first: its screen is the handler's, not the confirmation
            if case .required = viewModel.spendStep, let handler = viewModel.spendStepHandler {
                focusField = nil
                Coordinator.shared.present { isPresented in
                    handler.view(isPresented: isPresented) {
                        viewModel.syncSpendStep()
                    }
                }
                return
            }

            guard let resolvedAddress = viewModel.resolvedAddress, let data = viewModel.sendData?.sendData else { return }

            let address = viewModel.sendData?.address

            let proceedToSend = {
                if #available(iOS 17.0, *) {
                    focusField = nil
                    path.append(PreSendView.ConfirmationData(sendData: data, address: address))
                } else {
                    presentRegularSendView(sendData: data, address: address)
                }
            }
            if resolvedAddress.issueTypes.isEmpty {
                proceedToSend()
            } else {
                Coordinator.shared.present(type: .bottomSheet) { isPresented in
                    BottomSheetView(
                        items: [
                            .title(icon: ThemeImage.warning, title: "send.address.risky.title".localized),
                            .warning(text: "send.address.risky.description".localized),
                            .buttonGroup(.init(buttons: [
                                .init(style: .secondary, title: "send.continue_anyway".localized) {
                                    isPresented.wrappedValue = false
                                    proceedToSend()
                                },
                                .init(style: .secondary, mode: .transparent, title: "button.cancel".localized) { isPresented.wrappedValue = false },
                            ])),
                        ]
                    )
                }
            }
        }
        .disabled(state.disabled)
    }

    private func presentAddressPicker() {
        focusField = nil

        // No recipient chain until a token is chosen: pick the token first.
        guard let addressToken = viewModel.addressToken else {
            onSelectToken?()
            return
        }

        Coordinator.shared.present { isPresented in
            SendAddressViewWrapper(
                token: addressToken,
                fromAddress: viewModel.addressFromAddress,
                address: viewModel.resolvedAddress?.address,
                isPresented: isPresented
            ) { resolved in
                viewModel.set(address: resolved)
            }
        }
    }

    private func presentRegularSendView(sendData: SendData, address: String?) {
        Coordinator.shared.present { regularSendPresented in
            RegularSendViewWrapper(
                sendData: sendData,
                address: address,
                isPresented: regularSendPresented,
                onSuccess: {
                    HudHelper.instance.show(banner: .sent)
                    isPresented = false
                }
            )
        }
    }

    @ViewBuilder private func cautionsView() -> some View {
        let cautions = viewModel.cautions

        if !cautions.isEmpty {
            VStack(spacing: .margin12) {
                ForEach(cautions.indices, id: \.self) { index in
                    HighlightedTextView(caution: cautions[index])
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)
        }
    }
}

extension PreSendFormView where Footer == EmptyView {
    init(
        viewModel: BasePreSendViewModel,
        addressVisible: Bool,
        path: Binding<NavigationPath>,
        isPresented: Binding<Bool>,
        onSelectToken: (() -> Void)? = nil,
        @ViewBuilder fields: @escaping (FocusState<PreSendFocusField?>.Binding) -> Fields
    ) {
        self.init(viewModel: viewModel, addressVisible: addressVisible, path: path, isPresented: isPresented, onSelectToken: onSelectToken, fields: fields) {
            EmptyView()
        }
    }
}

enum PreSendFocusField: Hashable {
    case amount
    case fiatAmount
    case memo
    case destinationTag
}
