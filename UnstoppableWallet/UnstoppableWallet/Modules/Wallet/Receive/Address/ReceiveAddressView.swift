import Combine

import SwiftUI

private let qrSize: CGFloat = 203
private let appIconSize: CGFloat = 47

struct ReceiveAddressView: View {
    @StateObject var viewModel: ReceiveAddressViewModel
    var onDismiss: (() -> Void)?

    @State private var inputAmountPresented: Bool = false

    @Environment(\.presentationMode) private var presentationMode

    init(wallet: Wallet, onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss

        _viewModel = StateObject(wrappedValue: ReceiveAddressViewModel.instance(wallet: wallet))
    }

    var body: some View {
        ScrollableThemeView {
            switch viewModel.state {
            case .loading:
                ProgressView()
            case let .completed(viewItem):
                VStack(spacing: .margin12) {
                    if let description = viewItem.highlightedDescription {
                        HighlightedTextView(text: description.text, style: description.style)
                    }

                    ListSection {
                        qrView(item: viewItem.qrItem)
                        if let amount = viewItem.amount {
                            view(amount: amount)
                        }
                        if !viewItem.active {
                            notActive()
                        }
                        if !viewItem.assetActivated {
                            inactiveStellarAsset()
                        }
                        if let memo = viewItem.memo {
                            view(memo: memo)
                        }

                        if let usedAddresses = viewItem.usedAddresses, !usedAddresses.isEmpty {
                            NavigationRow(destination: {
                                UsedAddressesView(
                                    coinName: viewModel.coinName,
                                    title: viewModel.usedAddressesTitle,
                                    description: viewModel.usedAddressesDescription,
                                    hasChangeAddresses: viewModel.hasChangeAddresses,
                                    usedAddresses: usedAddresses,
                                    onDismiss: onDismiss ?? { presentationMode.wrappedValue.dismiss() }
                                )
                            }) {
                                Text(viewModel.usedAddressesTitle).themeSubhead2()
                                Image.disclosureIcon
                            }
                        }
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))

                Spacer().frame(height: 52)

                LazyVGrid(columns: viewModel.actions.map { _ in GridItem(.flexible(), alignment: .top) }, spacing: .margin16) {
                    ForEach(viewModel.actions, id: \.self) { action in
                        actionView(type: action)
                    }
                }
                .padding(.horizontal, .margin48)

                Spacer()
            case .failed:
                PlaceholderViewNew(icon: "sync_error_48", subtitle: "sync_error".localized)
            }
        }
        .textFieldAlert(
            isPresented: $inputAmountPresented,
            amountChanged: viewModel.onAmountChanged(_:),
            content: {
                TextFieldAlert(
                    title: "deposit.enter_amount".localized,
                    message: nil,
                    initial: viewModel.initialText
                )
            }
        )
        .alertButtonTint(color: .themeJacob)
        .onFirstAppear {
            viewModel.onFirstAppear()
        }
        .onReceive(viewModel.popupPublisher) { popup in
            Coordinator.shared.present(type: .bottomSheet) { isPresented in
                BottomSheetView(
                    icon: .warning,
                    title: popup.title,
                    items: [
                        .highlightedDescription(text: popup.description.text, style: popup.description.style),
                    ],
                    buttons: popupButtons(mode: popup.mode, isPresented: isPresented),
                    isPresented: isPresented
                )
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("button.done".localized) {
                    if let onDismiss {
                        onDismiss()
                    } else {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .accentColor(.themeJacob)
    }

    @ViewBuilder private func qrView(item: ReceiveAddressModule.QrItem) -> some View {
        VStack(spacing: .margin24) {
            if let uiImage = UIImage.qrCodeImage(qrCodeString: item.uri ?? item.address, size: qrSize) {
                ZStack {
                    Image(uiImage: uiImage)
                        .frame(width: qrSize, height: qrSize)
                        .padding(.margin2)
                        .background(Color.white)

                    Image(AppIcon.main.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: appIconSize, height: appIconSize)
                        .padding(.margin8)
                        .background(Color.white)
                }
            }

            VStack(spacing: .margin12) {
                Text(item.address)
                    .textSubhead2(color: .themeLeah)
                    .multilineTextAlignment(.center)

                if let networkName = item.networkName {
                    Text(networkName)
                        .textSubhead2()
                        .multilineTextAlignment(.center)
                }
            }
        }
        .gesture(
            TapGesture()
                .onEnded {
                    handle(action: .copy)
                }
        )
        .padding(EdgeInsets(top: .margin24, leading: .margin32, bottom: .margin24, trailing: .margin32))
    }

    @ViewBuilder private func actionView(type: ReceiveAddressModule.ActionType) -> some View {
        VStack(spacing: .margin8) {
            Button(action: {
                handle(action: type)
            }) {
                Image(type.icon).renderingMode(.template)
            }
            .buttonStyle(PrimaryCircleButtonStyle(style: .gray))

            Text(type.title).textSubhead1()
        }
    }

    private func handle(action: ReceiveAddressModule.ActionType) {
        guard let data = viewModel.state.data else {
            return
        }
        switch action {
        case .amount:
            inputAmountPresented = true
        case .share:
            Coordinator.shared.present { _ in
                ActivityView(activityItems: [data.copyValue])
            }
            stat(page: .receive, event: .share(entity: .receiveAddress))
        case .copy:
            CopyHelper.copyAndNotify(value: data.copyValue)
            stat(page: .receive, event: .copy(entity: .receiveAddress))
        }
    }

    @ViewBuilder func view(amount: String) -> some View {
        ListRow {
            Text("deposit.amount".localized).textSubhead2()
            Spacer()
            Text(amount).textSubhead1(color: .themeLeah)
            Button(action: {
                viewModel.set(amount: "")
                stat(page: .receive, event: .removeAmount)
            }, label: {
                Image("trash_20").renderingMode(.template)
            })
            .buttonStyle(SecondaryCircleButtonStyle(style: .default))
        }
    }

    @ViewBuilder func notActive() -> some View {
        ListRow(padding: EdgeInsets(top: .margin12, leading: 0, bottom: .margin12, trailing: .margin16)) {
            Text("deposit.account".localized)
                .textSubhead2()
                .modifier(
                    Informed(infoDescription: .init(
                        title: "deposit.not_active.title".localized,
                        description: "deposit.not_active.tron_description".localized
                    )))
            Spacer()
            Text("deposit.not_active".localized).textSubhead1(color: .themeYellow)
        }
    }

    @ViewBuilder func inactiveStellarAsset() -> some View {
        ClickableRow(action: {
            viewModel.showPopup()
        }) {
            HStack(spacing: .margin8) {
                Text("deposit.trustline".localized).textSubhead2()
                Image("circle_information_20").themeIcon()
            }
            Spacer()
            Text("deposit.trustline.not_activated".localized).textSubhead1(color: .themeYellow)
        }
    }

    @ViewBuilder func view(memo: String) -> some View {
        ListRow {
            Text("deposit.memo".localized)
                .textSubhead2()
                .modifier(
                    Informed(infoDescription: .init(
                        title: "deposit.memo_warning.title".localized,
                        description: "deposit.memo_warning.description".localized
                    )))
            Spacer()
            Text(memo).textSubhead1(color: .themeLeah)
            Button(action: {
                CopyHelper.copyAndNotify(value: memo)
            }, label: {
                Image("copy_20").renderingMode(.template)
            })
            .buttonStyle(SecondaryCircleButtonStyle(style: .default))
        }
    }

    private func popupButtons(mode: ReceiveAddressModule.PopupWarningItem.Mode, isPresented: Binding<Bool>) -> [BottomSheetView.ButtonItem] {
        switch mode {
        case let .done(title):
            return [
                .init(style: .yellow, title: title) {
                    isPresented.wrappedValue = false
                },
            ]
        case .activateStellarAsset:
            return [
                .init(style: .yellow, title: "deposit.activate".localized) {
                    isPresented.wrappedValue = false

                    Coordinator.shared.present { isPresented in
                        if let sendData = viewModel.stellarSendData {
                            ThemeNavigationStack {
                                RegularSendView(sendData: sendData) {
                                    HudHelper.instance.show(banner: .sent)
                                    isPresented.wrappedValue = false
                                }
                            }
                        }
                    }
                },
                .init(style: .transparent, title: "button.later".localized) {
                    isPresented.wrappedValue = false
                },
            ]
        }
    }
}
