import SwiftUI

struct MainTransactionsView: View {
    @ObservedObject var transactionsViewModel: TransactionsViewModel
    @Binding var isPresented: Bool

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                VStack(spacing: 0) {
                    ScrollableTabHeaderView(
                        tabs: TransactionTypeFilter.allCases.map(\.title),
                        currentTabIndex: Binding(
                            get: {
                                TransactionTypeFilter.allCases.firstIndex(of: transactionsViewModel.typeFilter) ?? 0
                            },
                            set: { index in
                                transactionsViewModel.typeFilter = TransactionTypeFilter.allCases[index]
                            }
                        )
                    )

                    if transactionsViewModel.sections.isEmpty {
                        PlaceholderViewNew(icon: "warning_filled", subtitle: "transactions.empty_text".localized)
                    } else {
                        ThemeList(bottomSpacing: .margin16) {
                            TransactionsView(viewModel: transactionsViewModel, statPage: .transactions)
                        }
                        .frame(maxHeight: .infinity)
                    }
                }
            }
            .navigationBarTitle("transactions.title".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image("close")
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        Coordinator.shared.present { isPresented in
                            TransactionFilterView(transactionsViewModel: transactionsViewModel, isPresented: isPresented)
                        }
                        stat(page: .transactions, event: .open(page: .transactionFilter))
                    }) {
                        Image("manage_2_24")
                            .modifier(ToolbarBadgeModifier(visible: transactionsViewModel.filterChanged))
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if transactionsViewModel.syncing {
                        ProgressView(value: 0.55)
                            .progressViewStyle(DeterminiteSpinnerStyle())
                            .frame(size: 24)
                            .spinning()
                    }
                }
            }
        }
    }
}
