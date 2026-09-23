import Kingfisher
import SwiftUI

struct PreSendView: View {
    @StateObject var viewModel: PreSendViewModel
    @StateObject private var privateSend: PrivateSendViewModel
    private let addressVisible: Bool
    private let onDismiss: () -> Void

    @Environment(\.presentationMode) private var presentationMode
    @FocusState private var focusField: FocusField?

    @Binding var path: NavigationPath

    init(wallet: Wallet, handler: IPreSendHandler?, resolvedAddress: ResolvedAddress, amount: Decimal? = nil, memo: String? = nil, addressVisible: Bool = true, path: Binding<NavigationPath>, onDismiss: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: PreSendViewModel(wallet: wallet, handler: handler, resolvedAddress: resolvedAddress, amount: amount, memo: memo))
        _privateSend = StateObject(wrappedValue: PrivateSendViewModel(token: wallet.token, service: Core.privateSendService))
        self.addressVisible = addressVisible
        _path = path
        self.onDismiss = onDismiss
    }

    var body: some View {
        ThemeView(style: .list) {
            BottomGradientWrapper(gradientColor: .themeLawrence) {
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 0) {
                            AvailableBalanceView(
                                balance: viewModel.availableBalance,
                                token: viewModel.token,
                                allAvailable: true,
                                currentValue: viewModel.amount,
                                onSelect: { percent in
                                    viewModel.setAmountIn(percent: percent)
                                    focusField = nil
                                },
                                onClear: {
                                    viewModel.clearAmountIn()
                                }
                            )
                            .padding(.top, 16)
                            .padding(.horizontal, 16)
                            .themeListTopView()

                            inputView()
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                                .padding(.bottom, 24)

                            if addressVisible {
                                inputSeparatorView()

                                Button(action: {
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    addressView()
                                        .padding(.horizontal, 16)
                                        .frame(height: 89)
                                }
                            }

                            Color.themeBlade.frame(height: .heightOnePixel)

                            if viewModel.memoType != .none {
                                memoView(type: viewModel.memoType)
                            }

                            if viewModel.destinationTagState != .hidden {
                                destinationTagView(state: viewModel.destinationTagState)
                            }

                            if !viewModel.cautions.isEmpty {
                                cautionsView()
                            }
                        }
                    }
                    .padding(.bottom, 32)
                }
                .themeListScrollHeader()
                .onTapGesture {
                    focusField = nil
                }
            } bottomContent: {
                buttonView()
            }
            .animation(.easeOut(duration: 0.25), value: focusField != nil)
        }
        .navigationDestination(for: ConfirmationData.self) { data in
            RegularSendView(sendData: data.sendData, address: data.address) {
                HudHelper.instance.show(banner: .sent)
                onDismiss()
            }
            .toolbarRole(.editor)
        }
        .navigationTitle(viewModel.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if let handler = viewModel.handler, handler.hasSettings {
                    Button(action: {
                        if let handler = viewModel.handler {
                            Coordinator.shared.present { _ in
                                handler.settingsView {
                                    viewModel.syncSendData()
                                }
                            }
                        }
                    }) {
                        Image("manage")
                            .modifier(ToolbarBadgeModifier(visible: handler.settingsModified))
                    }
                }
            }
        }
        .toolbarRole(.editor)
    }

    @ViewBuilder private func inputView() -> some View {
        SendInputView(
            token: viewModel.token,
            amountString: $viewModel.amountString,
            fiatAmountString: $viewModel.fiatAmountString,
            coinPrice: viewModel.coinPrice,
            currency: viewModel.currency,
            focusedField: $focusField,
            amountField: .amount,
            fiatField: .fiatAmount
        )
    }

    @ViewBuilder private func inputSeparatorView() -> some View {
        Color.themeBlade.frame(height: .heightOnePixel)
            .overlay {
                ThemeImage("arrow_m_down", size: 20)
                    .padding(6)
                    .background(Color.themeLawrence)
            }
    }

    @ViewBuilder private func privateSendView() -> some View {
        if privateSend.isSupported {
            ListSection {
                Cell(
                    left: {
                        ThemeImage("fraud", size: 24)
                    },
                    middle: {
                        MiddleTextIcon(text: "private_send.toggle.title".localized)
                            .modifier(Informed(infoDescription: .init(
                                title: "private_send.info.title".localized,
                                description: "private_send.info.description".localized,
                                icon: "fraud"
                            ), horizontalPadding: 0))
                    },
                    right: {
                        ThemeToggle(isOn: $privateSend.isEnabled.animation())
                    }
                )
            }
            .padding(.top, 8)
        }
    }

    @ViewBuilder private func addressView() -> some View {
        HStack(spacing: 16) {
            ThemeImage("wallet_filled", size: 40)

            HStack(spacing: 8) {
                ThemeText(viewModel.resolvedAddress.address, style: .headline1, colorStyle: viewModel.resolvedAddress.issueTypes.isEmpty ? .primary : .red)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                ThemeImage("arrow_s_down", size: 20, colorStyle: .primary)
            }

            Spacer()
        }
    }

    @ViewBuilder private func destinationTagView(state: DestinationTagState) -> some View {
        let input = viewModel.destinationTag.trimmingCharacters(in: .whitespacesAndNewlines)
        let invalid = !input.isEmpty && XrpDestinationTag.parse(input) == nil
        let infoText = invalid ? "send.xrp.destination_tag.invalid".localized : "send.xrp.destination_tag.info".localized
        let infoTextColorStyle: ColorStyle = invalid ? .red : (state == .required ? .yellow : .secondary)

        let fixedTag: UInt32? = {
            if case let .fixed(tag) = state { return tag }
            return nil
        }()
        let text: Binding<String> = fixedTag.map { .constant(String($0)) } ?? $viewModel.destinationTag

        VStack(alignment: .leading, spacing: 0) {
            InputTextView(
                placeholder: "send.xrp.destination_tag.title".localized,
                multiline: false,
                font: .themeBody,
                text: text
            )
            .keyboardType(.numberPad)
            .disabled(fixedTag != nil)
            .focused($focusField, equals: .destinationTag)
            .padding(16)

            Color.themeBlade.frame(height: .heightOnePixel)

            ThemeText(infoText, style: .caption, colorStyle: infoTextColorStyle)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
    }

    @ViewBuilder private func memoView(type: MemoType) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            InputTextView(
                placeholder: "send.confirmation.memo_placeholder".localized,
                multiline: true,
                font: .themeBody.italic(),
                text: $viewModel.memo
            )
            .focused($focusField, equals: .memo)
            .padding(16)

            Color.themeBlade.frame(height: .heightOnePixel)

            ThemeText(memoInfoText(type: type), style: .caption)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
    }

    private func memoInfoText(type: MemoType) -> String {
        switch type {
        case .onChainPrivate: return "send.memo.private_warning".localized
        case .local: return "send.memo.local_warning".localized
        default: return "send.memo.public_warning".localized
        }
    }

    @ViewBuilder private func buttonView() -> some View {
        let (title, disabled, showProgress) = buttonState()

        Button(action: {
            // The private path is built inline and synchronously — no quote, no commit, no await —
            // and is deliberately NOT gated on `viewModel.sendData`: under private send the deposit
            // transfer is built later, inside the handler, once the commit has produced a deposit
            // address and amount.
            let data: SendData?
            let address: String?

            if privateSend.isEnabled {
                if let amount = viewModel.amount {
                    data = .privateSend(request: privateSend.request(recipient: viewModel.resolvedAddress.address, amount: amount))
                } else {
                    data = nil
                }

                // The real recipient, never a deposit address.
                address = viewModel.resolvedAddress.address
            } else {
                data = viewModel.sendData?.sendData
                address = viewModel.sendData?.address
            }

            guard let data else { return }

            let proceedToSend = {
                if #available(iOS 17.0, *) {
                    focusField = nil
                    path.append(ConfirmationData(sendData: data, address: address))
                } else {
                    presentRegularSendView(sendData: data, address: address)
                }
            }
            if viewModel.resolvedAddress.issueTypes.isEmpty {
                proceedToSend()
            } else {
                Coordinator.shared.present(type: .bottomSheet) { isPresented in
                    BottomSheetView(
                        items: [
                            .title(icon: ThemeImage.warning, title: "send.address.risky.title".localized),
                            .warning(text: "send.address.risky.description".localized),
                            .buttonGroup(.init(buttons: [
                                .init(style: .red, title: "send.continue_anyway".localized) {
                                    isPresented.wrappedValue = false
                                    proceedToSend()
                                },
                                .init(style: .transparent, title: "button.cancel".localized) { isPresented.wrappedValue = false },
                            ])),
                        ],
                    )
                }
            }
        }) {
            HStack(spacing: .margin8) {
                if showProgress {
                    ProgressView()
                }

                Text(title)
            }
        }
        .disabled(disabled)
        .buttonStyle(PrimaryButtonStyle(style: .yellow))
    }

    private func presentRegularSendView(sendData: SendData, address: String?) {
        Coordinator.shared.present { regularSendPresented in
            RegularSendViewWrapper(
                sendData: sendData,
                address: address,
                isPresented: regularSendPresented,
                onSuccess: {
                    HudHelper.instance.show(banner: .sent)
                    onDismiss()
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

    private func buttonState() -> (String, Bool, Bool) {
        let title: String
        var disabled = true
        var showProgress = false

        if viewModel.adapterState == nil {
            title = "send.token_not_enabled".localized
        } else if let adapterState = viewModel.adapterState, adapterState.syncing {
            title = "send.token_syncing".localized
            showProgress = true
        } else if let adapterState = viewModel.adapterState, !adapterState.isSynced {
            title = "send.token_not_synced".localized
        } else if viewModel.amount == nil {
            title = "send.enter_amount".localized
        } else if let availableBalance = viewModel.availableBalance, let amount = viewModel.amount, amount > availableBalance {
            title = "send.insufficient_balance".localized
        } else {
            title = "send.next_button".localized
            // A private send has no inner SendData at this stage — it is built inside the handler
            // after the commit — so it must not be gated on `viewModel.sendData`.
            disabled = !privateSend.isEnabled && viewModel.sendData == nil
        }

        return (title, disabled, showProgress)
    }
}

extension PreSendView {
    private enum FocusField: Int, Hashable {
        case amount
        case fiatAmount
        case memo
        case destinationTag
    }

    struct ConfirmationData: Hashable, Equatable {
        let id = UUID()
        let sendData: SendData
        let address: String?

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }
    }
}
