import SwiftUI

private let qrSize: CGFloat = 203
private let appIconSize: CGFloat = 47

struct ReceiveAddressView<Service: IReceiveAddressService, Factory: IReceiveAddressViewItemFactory>: View where Service.ServiceItem == Factory.Item {
    @ObservedObject var viewModel: ReceiveAddressViewModel<Service, Factory>

    @State private var hasAppeared = false
    @State private var warningAlertPopup: ReceiveAddressModule.PopupWarningItem?

    @State private var infoPopup: AlertView.InfoDescription? = nil

    @State private var shareText: String?
    @State private var inputAmountPresented: Bool = false

    @State private var inputText: String = ""

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ScrollableThemeView {
            switch viewModel.state {
            case .loading:
                ProgressView()
            case let .completed(viewItem):
                VStack(spacing: .margin12) {
                    ForEach(viewItem.sections, id: \.self) { items in
                        view(items: items)
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))

                Spacer()
                    .frame(height: 52)

                LazyVGrid(columns: viewModel.actions.map { _ in GridItem(.flexible()) }, spacing: .margin16) {
                    ForEach(viewModel.actions, id: \.self) { action in
                        actionView(type: action)
                    }
                }
                .padding(.horizontal, .margin48)

                Spacer()
            case .failed:
                PlaceholderViewNew(image: Image("sync_error_48"), text: "sync_error".localized)
            }
        }
        .onChange(of: viewModel.popup) {
            print("Come on Change")
            guard hasAppeared else { return }
            print("Set Popup to VIEW")
            warningAlertPopup = $0
        }
        .sheet(item: $shareText) { shareText in
            ActivityView.view(activityItems: [shareText])
        }
        .alert("cex_deposit.enter_amount".localized, isPresented: $inputAmountPresented, actions: {
            TextField("Amount", text: $inputText) // TODO: Can't check valid numbers in default alertview
                .keyboardType(.decimalPad)
            Button("button.cancel".localized) {
                updateAmount(success: false)
            }
            Button("button.confirm".localized) {
                updateAmount(success: true)
            }
        })
        .alertButtonTint(color: .themeJacob)
        .bottomSheet(item: $warningAlertPopup) { popup in
            AlertView(
                image: .warning,
                title: popup.title,
                items: [
                    .highlightedDescription(text: popup.description.text, style: popup.description.style),
                ],
                buttons: [
                    .init(style: .yellow, title: popup.doneButtonTitle) { warningAlertPopup = nil },
                ],
                onDismiss: { warningAlertPopup = nil }
            )
        }
        .bottomSheet(item: $infoPopup) { popup in
            AlertView(
                image: .info,
                title: popup.title,
                items: [
                    .description(text: popup.description),
                ],
                onDismiss: { infoPopup = nil }
            )
        }
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true

            viewModel.onFirstAppear()
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("button.done".localized) {
                    presentationMode.wrappedValue.dismiss()
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

                    Image(uiImage: UIImage(named: AppIcon.main.imageName) ?? UIImage())
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
        case .amount: inputAmountPresented = true
        case .share: shareText = data.copyValue
        case .copy: CopyHelper.copyAndNotify(value: data.copyValue)
        }
    }

    private func updateAmount(success: Bool) {
        if success {
            viewModel.set(amount: inputText)
        } else {
            inputText = viewModel.amount == 0 ? "" : viewModel.amount.description
        }
    }

    @ViewBuilder private func view(item: ReceiveAddressModule.Item) -> some View {
        switch item {
        case let .qrItem(item): qrView(item: item)
        case let .value(title, value, _):
            ListRow {
                Text(title).textSubhead2()
                Spacer()
                Text(value).textSubhead1(color: .themeLeah)
            }
        case let .infoValue(title, value, infoTitle, infoDescription, style):
            ClickableRow(action: {
                infoPopup = AlertView.InfoDescription(title: infoTitle, description: infoDescription)
            }) {
                Text(title).textSubhead2()
                Image("circle_information_20").themeIcon()
                Spacer()
                Text(value).textSubhead1(color: style.accentColor)
            }
        case let .highlightedDescription(text, style):
            HighlightedTextView(text: text, style: style)
        }
    }

    @ViewBuilder private func view(items: [ReceiveAddressModule.Item]) -> some View {
        ListSection {
            ForEach(items) { item in
                view(item: item)
            }
        }
    }
}
