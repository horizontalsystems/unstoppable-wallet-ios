import ComponentKit
import Kingfisher
import MarketKit
import SwiftUI

struct SendView: View {
    @StateObject var viewModel: SendViewModel
    private let onSend: () -> Void

    @State private var feeSettingsPresented = false

    init(sendData: SendData, onSend: @escaping () -> Void) {
        _viewModel = .init(wrappedValue: SendViewModel(handler: SendHandlerFactory.handler(sendData: sendData)))
        self.onSend = onSend
    }

    var body: some View {
        ThemeView {
            if let handler = viewModel.handler {
                switch viewModel.state {
                case .syncing:
                    VStack(spacing: .margin12) {
                        ProgressView()

                        if let syncingText = handler.syncingText {
                            Text(syncingText).textSubhead2()
                        }
                    }
                case let .success(data):
                    dataView(data: data)
                case let .failed(error):
                    errorView(error: error)
                }
            } else {
                Text("No Handler")
            }
        }
        .sheet(isPresented: $feeSettingsPresented) {
            if let transactionService = viewModel.transactionService, let feeToken = viewModel.feeToken {
                transactionService.settingsView(
                    feeData: Binding<FeeData?>(get: { viewModel.state.data?.feeData }, set: { _ in }),
                    loading: Binding<Bool>(get: { viewModel.state.isSyncing }, set: { _ in }),
                    feeToken: feeToken,
                    currency: viewModel.currency,
                    feeTokenRate: $viewModel.feeTokenRate
                )
            }
        }
        .navigationTitle("send.confirmation.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    feeSettingsPresented = true
                }) {
                    Image("manage_2_20").renderingMode(.template)
                }
                .disabled(viewModel.state.isSyncing)
            }
        }
        .onReceive(viewModel.errorSubject) { error in
            HudHelper.instance.showError(subtitle: error)
        }
    }

    @ViewBuilder private func dataView(data: ISendConfirmationData) -> some View {
        VStack {
            ScrollView {
                VStack(spacing: .margin16) {
                    let sections = data.sections(feeToken: viewModel.feeToken, currency: viewModel.currency, feeTokenRate: viewModel.feeTokenRate)

                    if !sections.isEmpty {
                        ForEach(sections.indices, id: \.self) { sectionIndex in
                            let section = sections[sectionIndex]

                            if !section.isEmpty {
                                ListSection {
                                    ForEach(section.indices, id: \.self) { index in
                                        section[index].listRow
                                    }
                                }
                            }
                        }
                    }

                    let cautions = (viewModel.transactionService?.cautions ?? []) + data.cautions(feeToken: viewModel.feeToken)

                    if !cautions.isEmpty {
                        VStack(spacing: .margin12) {
                            ForEach(cautions.indices, id: \.self) { index in
                                HighlightedTextView(caution: cautions[index])
                            }
                        }
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            }

            if viewModel.timeLeft > 0 || viewModel.sending {
                SlideButton(
                    styling: .text(
                        start: data.sendButtonTitle,
                        end: data.sendingButtonTitle,
                        success: data.sentButtonTitle
                    ),
                    action: {
                        try await viewModel.send()
                    }, completion: {
                        onSend()
                    }
                )
                .padding(.vertical, .margin16)
                .padding(.horizontal, .margin16)
            } else {
                Button(action: {
                    viewModel.sync()
                }) {
                    Text("send.confirmation.refresh".localized)
                }
                .buttonStyle(PrimaryButtonStyle(style: .gray))
                .padding(.vertical, .margin16)
                .padding(.horizontal, .margin16)
            }

            let (bottomText, bottomTextColor) = bottomText()

            Text(bottomText)
                .textSubhead1(color: bottomTextColor)
                .padding(.bottom, .margin8)
        }
    }

    @ViewBuilder private func errorView(error: Error) -> some View {
        VStack {
            ScrollView {
                VStack(spacing: .margin16) {
                    HighlightedTextView(caution: CautionNew(text: error.smartDescription, type: .error))
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            }

            Button(action: {
                viewModel.sync()
            }) {
                Text("send.confirmation.refresh".localized)
            }
            .buttonStyle(PrimaryButtonStyle(style: .gray))
            .padding(.vertical, .margin16)
            .padding(.horizontal, .margin16)

            Text("send.confirmation.sync_failed".localized)
                .textSubhead1()
                .padding(.bottom, .margin8)
        }
    }

    private func bottomText() -> (String, Color) {
        if let data = viewModel.state.data, !data.canSend {
            return ("send.confirmation.invalid_data".localized, .themeGray)
        } else if viewModel.sending {
            return ("send.confirmation.please_wait".localized, .themeGray)
        } else if viewModel.timeLeft > 0 {
            return ("send.confirmation.expires_in".localized("\(viewModel.timeLeft)"), .themeJacob)
        } else {
            return ("send.confirmation.expired".localized, .themeGray)
        }
    }
}
