protocol IRestoreAccountsViewDelegate {
    var itemsCount: Int { get }
    func item(index: Int) -> PredefinedAccountType
    func didTapRestore(index: Int)
}

protocol IRestoreAccountsRouter {
    func showRestore(type: PredefinedAccountType)
}
