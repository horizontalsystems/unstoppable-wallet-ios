import Combine
import Foundation

protocol ITransactionInfoExtraProvider {
    func sections(item: TransactionInfoService.Item) -> [TransactionInfoModule.SectionViewItem]
    var updatedPublisher: AnyPublisher<Void, Never> { get }
}

extension ITransactionInfoExtraProvider {
    var updatedPublisher: AnyPublisher<Void, Never> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }
}

class TransactionInfoExtraFactory {
    private var providers: [ITransactionInfoExtraProvider] = []

    func register(_ provider: ITransactionInfoExtraProvider) {
        providers.append(provider)
    }

    func sections(item: TransactionInfoService.Item) -> [TransactionInfoModule.SectionViewItem] {
        providers.flatMap { $0.sections(item: item) }
    }

    var updatedPublisher: AnyPublisher<Void, Never> {
        Publishers.MergeMany(providers.map(\.updatedPublisher)).eraseToAnyPublisher()
    }
}
