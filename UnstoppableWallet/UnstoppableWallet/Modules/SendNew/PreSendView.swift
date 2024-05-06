import ComponentKit
import Kingfisher
import SwiftUI
import ThemeKit

struct PreSendView: View {
    @StateObject var viewModel: PreSendViewModel

    @Environment(\.presentationMode) private var presentationMode
    @FocusState private var focusField: FocusField?
    @FocusState var isAddressFocused: Bool

    @State private var settingsPresented = false
    @State private var confirmPresented = false

    init(wallet: Wallet, mode: PreSendViewModel.Mode = .regular) {
        _viewModel = StateObject(wrappedValue: PreSendViewModel(wallet: wallet, mode: mode))
    }

    var body: some View {
        ThemeView {
            ScrollView {
                VStack(spacing: .margin16) {
                    VStack(spacing: .margin8) {
                        inputView()
                        availableBalanceView(value: balanceValue())
                    }

                    if viewModel.addressVisible {
                        addressView()
                    }

                    buttonView()
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin16, trailing: .margin16))
                .animation(.linear, value: viewModel.addressCautionState)
            }

            NavigationLink(
                isActive: $confirmPresented,
                destination: {
                    if let sendData = viewModel.sendData {
                        RegularSendView(sendData: sendData) {
                            HudHelper.instance.show(banner: .sent)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            ) {
                EmptyView()
            }
        }
        .navigationTitle("Send \(viewModel.token.coin.code)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                KFImage.url(URL(string: viewModel.token.coin.imageUrl))
                    .resizable()
                    .frame(width: .iconSize24, height: .iconSize24)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                if let handler = viewModel.handler, handler.hasSettings {
                    Button(action: {
                        settingsPresented = true
                    }) {
                        Image("settings_24")
                            .renderingMode(.template)
                            .foregroundColor(.themeJacob)
                    }
                }
            }
        }
        .sheet(isPresented: $settingsPresented) {
            if let handler = viewModel.handler {
                handler.settingsView {
                    viewModel.syncSendData()
                }
            }
        }
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

    @ViewBuilder private func inputView() -> some View {
        VStack(spacing: 3) {
            TextField("", text: $viewModel.amountString, prompt: Text("0").foregroundColor(.themeGray))
                .foregroundColor(.themeLeah)
                .font(.themeHeadline1)
                .keyboardType(.decimalPad)
                .focused($focusField, equals: .amount)

            if viewModel.rate != nil {
                HStack(spacing: 0) {
                    Text(viewModel.currency.symbol).textBody(color: .themeGray)

                    TextField("", text: $viewModel.fiatAmountString, prompt: Text("0").foregroundColor(.themeGray))
                        .foregroundColor(.themeGray)
                        .font(.themeBody)
                        .keyboardType(.decimalPad)
                        .focused($focusField, equals: .fiatAmount)
                        .frame(height: 20)
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
        .onFirstAppear {
            focusField = .amount
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                if focusField != nil {
                    HStack(spacing: 0) {
                        if viewModel.availableBalance != nil {
                            ForEach(1 ... 4, id: \.self) { multiplier in
                                let percent = multiplier * 25

                                Button(action: {
                                    viewModel.setAmountIn(percent: percent)
                                    focusField = nil
                                }) {
                                    Text("\(percent)%").textSubhead1(color: .themeLeah)
                                }
                                .frame(maxWidth: .infinity)

                                RoundedRectangle(cornerRadius: 0.5, style: .continuous)
                                    .fill(Color.themeSteel20)
                                    .frame(width: 1)
                                    .frame(maxHeight: .infinity)
                            }
                        } else {
                            Spacer()
                        }

                        Button(action: {
                            viewModel.clearAmountIn()
                        }) {
                            Image(systemName: "trash")
                                .font(.themeSubhead1)
                                .foregroundColor(.themeLeah)
                        }
                        .frame(maxWidth: .infinity)

                        RoundedRectangle(cornerRadius: 0.5, style: .continuous)
                            .fill(Color.themeSteel20)
                            .frame(width: 1)
                            .frame(maxHeight: .infinity)

                        Button(action: {
                            focusField = nil
                        }) {
                            Image(systemName: "keyboard.chevron.compact.down")
                                .font(.themeSubhead1)
                                .foregroundColor(.themeLeah)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, -16)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    @ViewBuilder private func addressView() -> some View {
        AddressViewNew(
            initial: .init(
                blockchainType: viewModel.token.blockchainType,
                showContacts: true
            ),
            text: $viewModel.address,
            result: $viewModel.addressResult
        )
        .focused($isAddressFocused)
        .onChange(of: isAddressFocused) { active in
            viewModel.changeAddressFocus(active: active)
        }
        .modifier(CautionBorder(cautionState: $viewModel.addressCautionState))
        .modifier(CautionPrompt(cautionState: $viewModel.addressCautionState))
    }

    @ViewBuilder private func buttonView() -> some View {
        let (title, disabled, showProgress) = buttonState()

        Button(action: {
            confirmPresented = true
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

    private func balanceValue() -> String? {
        guard let availableBalance = viewModel.availableBalance else {
            return nil
        }

        return ValueFormatter.instance.formatFull(coinValue: CoinValue(kind: .token(token: viewModel.token), value: availableBalance))
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
        } else if case .idle = viewModel.addressResult {
            title = "send.enter_address".localized
        } else if case .loading = viewModel.addressResult {
            title = "send.enter_address".localized
        } else if case .invalid = viewModel.addressResult {
            title = "send.invalid_address".localized
        } else {
            title = "send.next_button".localized
            disabled = viewModel.sendData == nil
        }

        return (title, disabled, showProgress)
    }
}

extension PreSendView {
    private enum FocusField: Int, Hashable {
        case amount
        case fiatAmount
    }
}
