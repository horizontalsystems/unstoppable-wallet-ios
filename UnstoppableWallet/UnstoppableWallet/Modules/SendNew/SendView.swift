
import Kingfisher
import MarketKit
import SwiftUI

struct SendView: View {
    @ObservedObject var viewModel: SendViewModel

    var body: some View {
        ZStack {
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
                    dataView(data: data, handler: handler)
                case let .failed(error):
                    errorView(error: error)
                }
            } else {
                Text("No Handler")
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let transactionService = viewModel.transactionService, let feeToken = viewModel.handler?.baseToken {
                    Button(action: {
                        Coordinator.shared.present { _ in
                            transactionService.settingsView(
                                feeData: Binding<FeeData?>(get: { viewModel.state.data?.feeData }, set: { _ in }),
                                loading: Binding<Bool>(get: { viewModel.state.isSyncing }, set: { _ in }),
                                feeToken: feeToken,
                                currency: viewModel.currency,
                                feeTokenRate: Binding<Decimal?>(get: { viewModel.rates[feeToken.coin.uid] }, set: { _ in })
                            )
                        }
                    }) {
                        Image("manage_2_20").renderingMode(.template)
                    }
                    .disabled(viewModel.state.isSyncing)
                }
            }
        }
        .onReceive(viewModel.errorSubject) { error in
            HudHelper.instance.show(banner: .error(string: error))
        }
        .accentColor(.themeJacob)
    }

    @ViewBuilder private func dataView(data: ISendData, handler: ISendHandler) -> some View {
        ScrollView {
            VStack(spacing: .margin16) {
                let sections = data.sections(baseToken: handler.baseToken, currency: viewModel.currency, rates: viewModel.rates)

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

                let cautions = viewModel.cautions

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
    }

    @ViewBuilder private func errorView(error: Error) -> some View {
        ScrollView {
            VStack(spacing: .margin16) {
                HighlightedTextView(caution: CautionNew(text: error.smartDescription, type: .error))
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
    }
}
