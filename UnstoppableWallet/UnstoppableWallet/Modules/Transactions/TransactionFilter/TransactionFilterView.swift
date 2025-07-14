import SwiftUI

struct TransactionFilterView: View {
    @StateObject var viewModel: TransactionFilterViewModel
    @Binding var isPresented: Bool

    init(transactionsViewModel: TransactionsViewModelNew, isPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: TransactionFilterViewModel(transactionsViewModel: transactionsViewModel))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack {
            ScrollableThemeView {
                VStack(spacing: .margin32) {
                    ListSection {
                        ClickableRow(spacing: .margin8, action: {
                            Coordinator.shared.present { isPresented in
                                ThemeNavigationStack { TransactionBlockchainSelectView(transactionFilterViewModel: viewModel, isPresented: isPresented) }
                            }
                        }) {
                            Text("transaction_filter.blockchain".localized).textBody()

                            Spacer()

                            if let blockchain = viewModel.blockchain {
                                Text(blockchain.name).textSubhead1(color: .themeLeah)
                            } else {
                                Text("transaction_filter.all_blockchains".localized).textSubhead1()
                            }

                            Image("arrow_small_down_20").themeIcon()
                        }
                    }

                    ListSection {
                        ClickableRow(spacing: .margin8, action: {
                            Coordinator.shared.present { isPresented in
                                ThemeNavigationStack { TransactionTokenSelectView(transactionFilterViewModel: viewModel, isPresented: isPresented) }
                            }
                        }) {
                            Text("transaction_filter.coin".localized).textBody()

                            Spacer()

                            if let token = viewModel.token {
                                Text(token.coin.name).textSubhead1(color: .themeLeah)
                            } else {
                                Text("transaction_filter.all_coins".localized).textSubhead1()
                            }

                            Image("arrow_small_down_20").themeIcon()
                        }
                    }

                    ListSection {
                        ClickableRow(spacing: .margin8, action: {
                            Coordinator.shared.present { isPresented in
                                ThemeNavigationStack { TransactionContactSelectView(transactionFilterViewModel: viewModel, isPresented: isPresented) }
                            }
                        }) {
                            Text("transaction_filter.contact".localized).textBody()

                            Spacer()

                            if let contact = viewModel.contact {
                                Text(contact.name).textSubhead1(color: .themeLeah)
                            } else {
                                Text("transaction_filter.all_contacts".localized).textSubhead1()
                            }

                            Image("arrow_small_down_20").themeIcon()
                        }
                    }

                    VStack(spacing: 0) {
                        ListSection {
                            ListRow {
                                Toggle(isOn: Binding(get: { viewModel.scamFilterEnabled }, set: { viewModel.set(scamFilterEnabled: $0) })) {
                                    Text("transaction_filter.hide_suspicious_txs".localized).textBody()
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
                            }
                        }
                        ListSectionFooter(text: "transaction_filter.hide_suspicious_txs.description".localized)
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            }
            .navigationTitle("transaction_filter.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("button.reset".localized) {
                        viewModel.reset()
                    }
                    .disabled(!viewModel.resetEnabled)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("button.done".localized) {
                        isPresented = false
                    }
                }
            }
        }
        .accentColor(Color.themeJacob)
    }
}
