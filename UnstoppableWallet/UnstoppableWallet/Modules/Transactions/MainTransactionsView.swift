import SwiftUI

struct MainTransactionsView: View {
    @StateObject var transactionsViewModel = TransactionsViewModelNew()

    @State var presentedTransactionRecord: TransactionRecord?
    @State var transactionFilterPresented = false

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
        .sheet(isPresented: $transactionFilterPresented) {
            TransactionFilterView(transactionsViewModel: transactionsViewModel)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if transactionsViewModel.syncing {
                    ProgressView()
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    transactionFilterPresented = true
                }) {
                    ZStack {
                        Image("manage_2_24").themeIcon(color: .themeGray)

                        if transactionsViewModel.transactionFilter.hasChanges {
                            VStack {
                                HStack {
                                    Spacer()
                                    Circle().fill(Color.red).frame(width: 8, height: 8)
                                }
                                Spacer()
                            }
                        }
                    }
                    .frame(width: 28, height: 28)
                }
            }
        }
        .navigationTitle("transactions.title".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}
