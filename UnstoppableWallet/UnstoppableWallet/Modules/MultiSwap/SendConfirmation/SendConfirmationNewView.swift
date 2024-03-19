import ComponentKit
import Kingfisher
import MarketKit
import SwiftUI

struct SendConfirmationNewView: View {
    @StateObject var viewModel: SendConfirmationNewViewModel
    private let onSend: () -> Void

    @State private var feeSettingsPresented = false

    init(sendData: SendDataNew, onSend: @escaping () -> Void) {
        _viewModel = .init(wrappedValue: SendConfirmationNewViewModel(sendData: sendData))
        self.onSend = onSend
    }

    var body: some View {
        ThemeView {
            if viewModel.syncing {
                ProgressView()
            } else if let data = viewModel.data {
                dataView(data: data)
            }
        }
        .sheet(isPresented: $feeSettingsPresented) {
            if let transactionService = viewModel.transactionService, let feeToken = viewModel.feeToken {
                transactionService.settingsView(
                    feeData: Binding<FeeData?>(get: { viewModel.data?.feeData }, set: { _ in }),
                    loading: $viewModel.syncing,
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
                .disabled(viewModel.syncing)
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

            SlideButton(
                styling: .text(
                    start: data.customSendButtonTitle ?? "send.confirmation.slide_to_send".localized,
                    end: data.customSendingButtonTitle ?? "send.confirmation.sending".localized,
                    success: data.customSentButtonTitle ?? "send.confirmation.sent".localized
                ),
                action: {
                    try await viewModel.send()
                }, completion: {
                    onSend()
                }
            )
            .padding(.vertical, .margin16)
            .padding(.horizontal, .margin16)
        }
    }
}
