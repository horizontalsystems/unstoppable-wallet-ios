import SwiftUI

enum TransactionFilterModule {
    static func view(transactionsService: TransactionsService) -> some View {
        let viewModel = TransactionFilterViewModel(service: transactionsService)
        return TransactionFilterView(viewModel: viewModel)
    }
}
