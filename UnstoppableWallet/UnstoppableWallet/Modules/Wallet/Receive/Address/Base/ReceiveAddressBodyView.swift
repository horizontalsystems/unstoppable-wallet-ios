import SwiftUI

struct ReceiveAddressBodyView<Content: View>: View {
    private let qrSize: CGFloat = 203
    private let appIconSize: CGFloat = 47

    @StateObject var viewModel: BaseReceiveAddressViewModel
    private let content: () -> Content

    @State private var inputAmountPresented: Bool = false

    init(viewModel: BaseReceiveAddressViewModel, @ViewBuilder content: @escaping () -> Content) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            switch viewModel.state {
            case .loading:
                ProgressView()
            case let .completed(viewItem):
                VStack(spacing: .margin16) {
                    if let description = viewItem.highlightedDescription {
                        AlertCardView(.init(text: description.text, type: description.style == .yellow ? .caution : .critical, style: .inline))
                    }

                    ListSection {
                        qrView(item: viewItem.qrItem)
                        if let amount = viewItem.amount {
                            view(amount: amount)
                        }

                        content()
                    }
                }
                .padding(EdgeInsets(top: .margin16, leading: .margin16, bottom: .margin24, trailing: .margin16))

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
}
