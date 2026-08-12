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
        ThemeView {
            BottomGradientWrapper {
                ScrollView {
                    VStack(spacing: .margin16) {
                        if addressVisible {
                            if viewModel.resolvedAddress.issueTypes.isEmpty {
                                addressView()
                            } else {
                                addressView()
                                    .overlay(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous).stroke(Color.themeRed50, lineWidth: .heightOneDp))
                            }
                        }

                        VStack(spacing: .margin8) {
                            inputView()
                            availableBalanceView(value: balanceValue())
                            privateSendView()
                        }

                        if viewModel.memoType != .none {
                            memoView(type: viewModel.memoType)
                        }

                        if !viewModel.cautions.isEmpty {
                            cautionsView()
                        }
                    }
                    .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin16, trailing: .margin16))
                    .animation(.linear, value: viewModel.memoType)
                }
                .onTapGesture {
                    focusField = nil
                }
            } bottomContent: {
                buttonView()
            } keyboardContent: {
                AmountAccessoryView(
                    visible: focusField != nil,
                    enabledPercents: (viewModel.availableBalance ?? 0) > 0,
                    onPercent: { percent in
                        viewModel.setAmountIn(percent: percent)
                        focusField = nil
                    },
                    onTrash: {
                        viewModel.clearAmountIn()
                    }
                )
            }
            .animation(.easeOut(duration: 0.25), value: focusField)
        }
        // .onFirstAppear {
        //     focusField = .amount
        // }
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
                        Image("gear")
                            .modifier(ToolbarBadgeModifier(visible: handler.settingsModified))
                    }
                }
            }
        }
        .toolbarRole(.editor)
    }

    @ViewBuilder private func availableBalanceView(value: String?) -> some View {
        HStack(spacing: .margin8) {
            Text("send.available_balance".localized).textCaption()
            Spacer()
            Text(value ?? "---")
                .textCaption()
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, .margin16)
    }

    @ViewBuilder private func privateSendView() -> some View {
        // Not rendered at all for an unsupported token, not merely disabled. `isSupported` is a
        // synchronous read of the already-synced confidential token cache — this screen performs no
        // network work.
        if privateSend.isSupported {
            ListSection {
                Cell(
                    middle: {
                        MultiText(
                            title: "private_send.toggle.title".localized,
                            subtitle: "private_send.toggle.subtitle".localized
                        )
                    },
                    right: {
                        ThemeToggle(isOn: $privateSend.isEnabled.animation())
                    }
                )
            }
        }
    }

    @ViewBuilder private func inputView() -> some View {
        VStack(spacing: 3) {
            TextField("", text: $viewModel.amountString, prompt: Text("0").foregroundColor(.themeGray))
                .foregroundColor(.themeLeah)
                .font(.themeHeadline1)
                .tint(.themeInputFieldTintColor)
                .keyboardType(.decimalPad)
                .focused($focusField, equals: .amount)

            if let coinPrice = viewModel.coinPrice {
                HStack(spacing: 0) {
                    Text(viewModel.currency.symbol).textBody(color: .themeGray)

                    TextField("", text: $viewModel.fiatAmountString, prompt: Text("0").foregroundColor(.themeGray))
                        .foregroundColor(.themeGray)
                        .font(.themeBody)
                        .tint(.themeInputFieldTintColor)
                        .keyboardType(.decimalPad)
                        .focused($focusField, equals: .fiatAmount)
                        .frame(height: 20)
                        .disabled(coinPrice.expired)
                }
            } else {
                Text("swap.rate_not_available".localized)
                    .themeSubhead2(color: .themeGray50, alignment: .leading)
                    .frame(height: 20)
            }
        }
        .padding(.horizontal, .margin16)
        .padding(.vertical, 20)
        .modifier(ThemeListStyleModifier(cornerRadius: 18))
    }

    @ViewBuilder private func addressView() -> some View {
        ListSection {
            ClickableRow {
                presentationMode.wrappedValue.dismiss()
            } content: {
                Text("send.confirmation.to".localized).textSubhead2()

                Text(viewModel.resolvedAddress.address)
                    .textSubhead2(color: .themeLeah)
                    .multilineTextAlignment(.leading)

                Spacer()

                if !viewModel.resolvedAddress.issueTypes.isEmpty {
                    Image.warningIcon
                }

                Image("arrow_small_down_20").themeIcon()
            }
        }
    }

    @ViewBuilder private func memoView(type: MemoType) -> some View {
        let cautionState = CautionState.caution(Caution(text: memoWarningText(type: type), type: .warning))

        InputTextRow {
            InputTextView(
                placeholder: "send.confirmation.memo_placeholder".localized,
                multiline: true,
                font: .themeBody.italic(),
                text: $viewModel.memo
            )
        }
        .modifier(CautionBorder(cautionState: .constant(cautionState)))
        .modifier(CautionPrompt(cautionState: .constant(cautionState)))
    }

    private func memoWarningText(type: MemoType) -> String {
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

        VStack(spacing: .margin12) {
            ForEach(cautions.indices, id: \.self) { index in
                HighlightedTextView(caution: cautions[index])
            }
        }
    }

    private func balanceValue() -> String? {
        guard let availableBalance = viewModel.availableBalance else {
            return nil
        }

        return AppValue(token: viewModel.token, value: availableBalance).formattedFull()
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
