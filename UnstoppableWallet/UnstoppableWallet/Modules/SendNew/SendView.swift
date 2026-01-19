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
                    if let sendData = viewModel.sendData {
                        dataView(sendData: sendData, handler: handler)
                    } else {
                        VStack(spacing: .margin12) {
                            ProgressView()

                            if let syncingText = handler.syncingText {
                                Text(syncingText).textSubhead2()
                            }
                        }
                        .frame(maxHeight: .infinity)
                    }
                case .success:
                    if let sendData = viewModel.sendData {
                        dataView(sendData: sendData, handler: handler)
                    }
                case let .failed(error):
                    errorView(error: error)
                }
            } else {
                Text("No Handler")
            }
        }
        .toolbar {
            if let handler = viewModel.handler {
                let menuItems = menuItems(handler: handler)

                if !menuItems.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Group {
                            if menuItems.count > 1 {
                                Menu {
                                    ForEach(menuItems.indices, id: \.self) { index in
                                        let menuItem = menuItems[index]
                                        Button(menuItem.label, action: menuItem.action)
                                    }
                                } label: {
                                    Image("manage").renderingMode(.template)
                                }
                            } else {
                                Button(action: menuItems[0].action) {
                                    Image("manage").renderingMode(.template)
                                }
                            }
                        }
                        .disabled(!viewModel.state.isSuccess)
                    }
                }
            }
        }
        .onReceive(viewModel.errorPublisher) { error in
            Coordinator.shared.present(type: .bottomSheet) { isPresented in
                BottomSheetView(
                    items: [
                        .title(icon: ThemeImage.error, title: "send.confirmation.unexpected_error".localized),
                        .text(text: "send.confirmation.unexpected_error.text".localized),
                        .buttonGroup(.init(buttons: [
                            .init(style: .gray, title: "button.copy_error".localized, action: {
                                CopyHelper.copyAndNotify(value: error)
                                isPresented.wrappedValue = false
                            }),
                        ])),
                    ],
                )
            }

            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        .accentColor(.themeJacob)
    }

    @ViewBuilder private func dataView(sendData: ISendData, handler: ISendHandler) -> some View {
        ScrollView {
            VStack(spacing: .margin16) {
                let sections = sendData.sections(baseToken: handler.baseToken, currency: viewModel.currency, rates: viewModel.rates)

                if !sections.isEmpty {
                    ForEach(sections.indices, id: \.self) { sectionIndex in
                        let section = sections[sectionIndex]

                        if !section.fields.isEmpty {
                            if section.isList {
                                ListSection {
                                    VStack(spacing: 0) {
                                        fieldList(section: section)
                                    }
                                    .padding(.vertical, section.isMain ? 0 : 8)
                                }
                            } else {
                                fieldList(section: section)
                            }
                        }
                    }
                }

                let cautions = viewModel.cautions

                if !cautions.isEmpty {
                    VStack(spacing: .margin12) {
                        ForEach(cautions.indices, id: \.self) { index in
                            AlertCardView(caution: cautions[index])
                        }
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
    }

    @ViewBuilder private func fieldList(section: SendDataSection) -> some View {
        ForEach(section.fields.indices, id: \.self) { index in
            section.fields[index].listRow
            if section.isFlow, index < (section.fields.count - 1) {
                flowDivider()
            }
        }
    }

    @ViewBuilder private func flowDivider() -> some View {
        HorizontalDivider()
            .overlay(
                Circle()
                    .fill(Color.themeLawrence)
                    .frame(width: 20, height: 20)
                    .overlay(
                        ThemeImage("arrow_m_down", size: .iconSize20)
                    )
            )
    }

    @ViewBuilder private func errorView(error: Error) -> some View {
        PlaceholderViewNew(icon: "warning_filled", subtitle: "send.confirmation.failed_to_fetch_data".localized) {
            ThemeButton(text: "button.copy_error".localized, mode: .transparent, size: .small) {
                CopyHelper.copyAndNotify(value: error.smartDescription)
            }
        }
    }

    private func menuItems(handler: ISendHandler) -> [SendMenuItem] {
        var menuItems = [SendMenuItem]()

        if let transactionService = viewModel.transactionService {
            if let feeData = viewModel.sendData?.feeData {
                menuItems.append(
                    .init(label: "send.confirmation.edit_fee".localized) {
                        viewModel.stopAutoQuoting()

                        Coordinator.shared.present { _ in
                            FeeSettingsViewFactory.createSettingsView(
                                transactionService: transactionService,
                                feeData: feeData,
                                feeToken: handler.baseToken,
                                currency: viewModel.currency,
                                feeTokenRate: viewModel.rates[handler.baseToken.coin.uid]
                            )
                        } onDismiss: {
                            viewModel.autoQuoteIfRequired()
                        }
                    }
                )
            }

            if let service = transactionService as? EvmTransactionService {
                menuItems.append(
                    .init(label: "send.confirmation.transaction_nonce".localized) {
                        viewModel.stopAutoQuoting()

                        Coordinator.shared.present { _ in
                            TransactionNonceView(service: service)
                        } onDismiss: {
                            viewModel.autoQuoteIfRequired()
                        }
                    }
                )
            }
        }

        return menuItems + handler.menuItems
    }
}
