import Combine
import Foundation

final class ActivityViewModel: ObservableObject {
    let transactionsViewModel = TransactionsViewModel()
    private let swapHistoryViewModels: [ActivityTab: SwapHistoryViewModel]

    private var cancellables = Set<AnyCancellable>()

    @Published var selectedTab: ActivityTab = .transfer {
        didSet {
            guard selectedTab != oldValue else {
                return
            }

            stat(page: .transactions, event: .switchTab(tab: selectedTab.statTab))
        }
    }

    init() {
        let filter = transactionsViewModel.transactionFilter

        var swapHistoryViewModels = [ActivityTab: SwapHistoryViewModel]()

        for tab in ActivityTab.allCases {
            if let operations = tab.operations {
                swapHistoryViewModels[tab] = SwapHistoryViewModel(operations: operations, transactionFilter: filter)
            }
        }

        self.swapHistoryViewModels = swapHistoryViewModels

        transactionsViewModel.$transactionFilter
            .receive(on: DispatchQueue.main)
            .sink { [weak self] filter in
                self?.swapHistoryViewModels.values.forEach { $0.transactionFilter = filter }
            }
            .store(in: &cancellables)
    }

    /// nil for the transfer tab, which shows `transactionsViewModel`
    func swapHistoryViewModel(for tab: ActivityTab) -> SwapHistoryViewModel? {
        swapHistoryViewModels[tab]
    }
}
