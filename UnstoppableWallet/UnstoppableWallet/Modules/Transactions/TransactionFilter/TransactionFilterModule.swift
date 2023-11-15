import SwiftUI

struct TransactionFilterModule {
    static func view(transactionFilterService: TransactionFilterService) -> some View {
        let viewModel = TransactionFilterViewModel(service: transactionFilterService)
        return TransactionFilterView(viewModel: viewModel)
    }
}
