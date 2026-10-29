import SwiftUI

struct TransactionFilterView: View {
    @StateObject var viewModel: TransactionFilterViewModel
    @Binding var isPresented: Bool

    init(transactionsViewModel: TransactionsViewModel, isPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: TransactionFilterViewModel(transactionsViewModel: transactionsViewModel))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack {
            ScrollableThemeView {
                VStack(spacing: .margin32) {
                    ListSection {
                        dropdownRow(
                            title: "transaction_filter.blockchain".localized,
                            value: viewModel.blockchain?.name,
                            defaultValue: "transaction_filter.all_blockchains".localized
                        ) {
                            Coordinator.shared.present { isPresented in
                                ThemeNavigationStack { TransactionBlockchainSelectView(transactionFilterViewModel: viewModel, isPresented: isPresented) }
                            }
                        }
                    }

                    ListSection {
                        dropdownRow(
                            title: "transaction_filter.coin".localized,
                            value: viewModel.token?.coin.name,
                            defaultValue: "transaction_filter.all_coins".localized
                        ) {
                            Coordinator.shared.present { isPresented in
                                ThemeNavigationStack { TransactionTokenSelectView(transactionFilterViewModel: viewModel, isPresented: isPresented) }
                            }
                        }
                    }

                    ListSection {
                        dropdownRow(
                            title: "transaction_filter.contact".localized,
                            value: viewModel.contact?.name,
                            defaultValue: "transaction_filter.all_contacts".localized
                        ) {
                            Coordinator.shared.present { isPresented in
                                ThemeNavigationStack { TransactionContactSelectView(transactionFilterViewModel: viewModel, isPresented: isPresented) }
                            }
                        }
                    }

                    VStack(spacing: 0) {
                        ListSection {
                            Cell(
                                middle: { ThemeText("transaction_filter.hide_suspicious_txs".localized, style: .headline2) },
                                right: { ThemeToggle(isOn: Binding(get: { viewModel.scamFilterEnabled }, set: { viewModel.set(scamFilterEnabled: $0) })) }
                            )
                        }
                        ListSectionFooter(text: "transaction_filter.hide_suspicious_txs.description".localized)
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            }
            .navigationTitle("transaction_filter.title".localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.reset()
                    }) {
                        Image("reset")
                    }
                    .disabled(!viewModel.resetEnabled)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image("check")
                    }
                    .modifier(ConfirmationButtonStyle())
                }
            }
        }
    }

    @ViewBuilder private func dropdownRow(title: String, value: String?, defaultValue: String, action: @escaping () -> Void) -> some View {
        Cell(
            middle: { ThemeText(title, style: .headline2) },
            right: {
                ThemeText(value ?? defaultValue, style: .subheadSB, colorStyle: value == nil ? .secondary : .primary)
                    .arrow(style: .dropdown)
            },
            action: action
        )
    }
}
