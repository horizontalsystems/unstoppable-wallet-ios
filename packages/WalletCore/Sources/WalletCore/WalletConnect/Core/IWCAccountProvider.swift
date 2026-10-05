import Combine

// Slice of AccountManager the module depends on
protocol IWCAccountProvider: AnyObject {
    var activeAccount: Account? { get }
    var activeAccountIdPublisher: AnyPublisher<String?, Never> { get }
    var deletedAccountIdPublisher: AnyPublisher<String, Never> { get }
}

extension IWCAccountProvider {
    var activeAccountId: String? { activeAccount?.id }
}

extension AccountManager: IWCAccountProvider {
    var activeAccountIdPublisher: AnyPublisher<String?, Never> {
        activeAccountPublisher.map { $0?.id }.eraseToAnyPublisher()
    }

    var deletedAccountIdPublisher: AnyPublisher<String, Never> {
        accountDeletedPublisher.map(\.id).eraseToAnyPublisher()
    }
}
