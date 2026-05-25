import Combine
import Foundation
import RxSwift
import WalletCore

final class AppTransactionAdapterManager {
    private var cancellables = Set<AnyCancellable>()

    private let engine: TransactionAdapterManager

    init(engine: TransactionAdapterManager, appAdapterManager: AppAdapterManager) {
        self.engine = engine

        appAdapterManager.adapterDataReadyPublisher
            .sink { [weak self] adapterData in
                self?.engine.handleAdapterDataUpdate(adapterData.adapterMap)
            }
            .store(in: &cancellables)
    }
}

extension AppTransactionAdapterManager {
    var adapterMap: [TransactionSource: ITransactionsAdapter] {
        engine.adapterMap
    }

    var adaptersReadyPublisher: AnyPublisher<Void, Never> {
        engine.adaptersReadyPublisher
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func adapter(for source: TransactionSource) -> ITransactionsAdapter? {
        engine.adapter(for: source)
    }
}
