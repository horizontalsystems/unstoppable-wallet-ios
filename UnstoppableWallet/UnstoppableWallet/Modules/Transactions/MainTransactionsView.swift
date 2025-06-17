import SwiftUI

struct MainTransactionsView: View {
    @ObservedObject var transactionsViewModel: TransactionsViewModelNew

    @State var presentedTransactionRecord: TransactionRecord?

    var body: some View {
        ThemeView(isRoot: true) {
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
                    PlaceholderViewNew(image: Image("outgoing_raw_48"), text: "transactions.empty_text".localized)
                } else {
                    ThemeList(bottomSpacing: .margin16) {
                        TransactionsView(viewModel: transactionsViewModel, presentedTransactionRecord: $presentedTransactionRecord)
                    }
                    .frame(maxHeight: .infinity)
                }
            }
        }
        .sheet(item: $presentedTransactionRecord) { record in
            TransactionInfoView(transactionRecord: record).ignoresSafeArea()
        }
    }
}
