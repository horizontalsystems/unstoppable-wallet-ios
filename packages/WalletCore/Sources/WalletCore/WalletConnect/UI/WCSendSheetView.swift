import SwiftUI

// Transaction request as a bottom sheet: the SendNew data rendered as BSModule blocks, sized by the coordinator
struct WCSendSheetView: View {
    private let item: WCRequestItem
    @StateObject private var sendViewModel: SendViewModel
    @Binding private var isPresented: Bool
    @State private var finished = false

    init(item: WCRequestItem, sendData: SendData, isPresented: Binding<Bool>) {
        self.item = item
        _sendViewModel = StateObject(wrappedValue: SendViewModel(sendData: sendData))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeView(style: .list) {
            VStack(spacing: 0) {
                content
                buttons
                    .padding(EdgeInsets(top: .margin24, leading: .margin24, bottom: .margin16, trailing: .margin24))
            }
        }
        .onReceive(sendViewModel.errorPublisher) { error in
            HudHelper.instance.show(banner: .error(string: error))
        }
        .onDisappear {
            // a blocked request is answered with an error as soon as the sheet goes away
            if !finished, item.request?.isBlocked == true { reject() }
        }
        .interactiveDismissDisabled(sendViewModel.sending)
    }

    @ViewBuilder private var content: some View {
        switch sendViewModel.state {
        case .syncing, .success:
            if let sendData = sendViewModel.sendData, let handler = sendViewModel.handler {
                sectionViews(sendData: sendData, handler: handler)
            } else {
                ProgressView()
                    .padding(.vertical, .margin32)
            }
        case let .failed(error):
            BSModule.view(for: .error(text: (error as? UserFacingError)?.errorDescription ?? "send.confirmation.failed_to_fetch_data".localized))
        }
    }

    @ViewBuilder private func sectionViews(sendData: ISendData, handler: ISendHandler) -> some View {
        let sections = sendData.sections(baseToken: handler.baseToken, currency: sendViewModel.currency, rates: sendViewModel.rates)

        ForEach(sections.indices, id: \.self) { index in
            let section = sections[index]
            if section.isList {
                ListSection {
                    section.fieldList
                }
                .themeListStyle(.borderedPlain)
                .padding(.horizontal, .margin16)
                .padding(.top, .margin8)
            } else {
                section.fieldList
            }
        }

        let cautions = sendViewModel.cautions
        ForEach(cautions.indices, id: \.self) { index in
            AlertCardView(caution: cautions[index])
                .padding(.horizontal, .margin16)
                .padding(.top, .margin8)
        }
    }

    @ViewBuilder private var buttons: some View {
        HStack(spacing: .margin8) {
            Button(action: {
                reject()
                isPresented = false
            }) {
                Text("button.reject".localized)
            }
            .buttonStyle(PrimaryButtonStyle(style: .gray))
            .disabled(sendViewModel.sending)

            switch sendViewModel.state {
            case .syncing:
                EmptyView()
            case .success:
                Button(action: { send() }) {
                    HStack(spacing: .margin8) {
                        if sendViewModel.sending { ProgressView().progressViewStyle(.circular) }
                        Text(sendViewModel.sendData?.customSendButtonTitle ?? "wallet_connect.button.confirm".localized)
                    }
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
                .disabled(sendViewModel.sending || !(sendViewModel.sendData?.canSend ?? false))
            case .failed:
                Button(action: { sendViewModel.sync() }) {
                    Text("send.confirmation.refresh".localized)
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
            }
        }
    }

    private func send() {
        Task {
            // the error is already surfaced through errorPublisher; close either way so a confirmed
            // transaction can never be broadcast a second time (matches Android)
            try? await sendViewModel.send()
            await MainActor.run {
                finished = true
                isPresented = false
            }
        }
    }

    private func reject() {
        guard !finished, let kit = Core.shared.walletConnect?.startedKit else { return }
        finished = true
        Task { try? await kit.reject(item: item) }
    }
}
