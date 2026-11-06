import SwiftUI

struct TransactionsView: View {
    @ObservedObject var viewModel: TransactionsViewModel
    let statPage: StatPage

    var body: some View {
        ForEach(viewModel.sections) { section in
            Section {
                ForEach(section.viewItems) { viewItem in
                    ItemView(viewItem: viewItem, isLast: viewItem.id == section.viewItems.last?.id) {
                        if let record = viewModel.record(id: viewItem.id) {
                            TransactionInfoModule.present(transactionRecord: record)
                            stat(page: statPage, event: .open(page: .transactionInfo))
                        }
                    }
                    .onAppear {
                        viewModel.onDisplay(viewItem: viewItem)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                }
            } header: {
                ThemeListSectionHeader(text: section.title)
            }
            .listSectionSeparator(.hidden)
        }
    }

    struct ItemView: View, Equatable {
        let viewItem: TransactionsViewModel.ViewItem
        let isLast: Bool
        let action: () -> Void

        var body: some View {
            ActivityCellView(viewItem: viewItem.cell, isLast: isLast, action: action)
                .accessibilityIdentifier(TestTags.txItem(viewItem.uid))
        }

        static func == (lhs: ItemView, rhs: ItemView) -> Bool {
            lhs.viewItem == rhs.viewItem && lhs.isLast == rhs.isLast
        }
    }
}
