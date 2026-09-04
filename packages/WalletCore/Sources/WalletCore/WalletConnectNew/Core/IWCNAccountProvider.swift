import Combine

// Slice of AccountManager the session service depends on
protocol IWCNAccountProvider: AnyObject {
    var activeAccountId: String? { get }
    var activeAccountIdPublisher: AnyPublisher<String?, Never> { get }
    var deletedAccountIdPublisher: AnyPublisher<String, Never> { get }
}

extension AccountManager: IWCNAccountProvider {
    var activeAccountId: String? { activeAccount?.id }

    var activeAccountIdPublisher: AnyPublisher<String?, Never> {
        activeAccountPublisher.map { $0?.id }.eraseToAnyPublisher()
    }

    var deletedAccountIdPublisher: AnyPublisher<String, Never> {
        accountDeletedPublisher.map(\.id).eraseToAnyPublisher()
    }
}
