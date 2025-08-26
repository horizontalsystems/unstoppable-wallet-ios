import SwiftUI

struct MainTransactionsView: View {
    @ObservedObject var transactionsViewModel: TransactionsViewModel

    var body: some View {
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
                    PlaceholderViewNew(icon: "outgoing_raw_48", subtitle: "transactions.empty_text".localized)
                } else {
                    ThemeList(bottomSpacing: .margin16) {
                        TransactionsView(viewModel: transactionsViewModel, statPage: .transactions)
                    }
                    .frame(maxHeight: .infinity)
                }
            }
        }
    }
}
