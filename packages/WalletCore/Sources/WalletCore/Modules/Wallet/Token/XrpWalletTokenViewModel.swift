import Combine
import Foundation
import RxSwift
import XrpKit

/// Native XRP token page: the reserve breakdown (Android `XrpAdapter.reserveInfo`) and the
/// not-activated state of the account, shown as the transaction-list status text (Android
/// `XrpInactiveAccountWarning`); no popup, unlike Tron.
class XrpWalletTokenViewModel: ObservableObject {
    private let balanceHiddenManager = Core.shared.balanceHiddenManager
    private let adapter: XrpAdapter

    private var cancellables = Set<AnyCancellable>()
    private let disposeBag = DisposeBag()

    @Published var reserveInfo: XrpReserveInfo?
    @Published var accountActive: Bool
    @Published var balanceHidden: Bool

    init(adapter: XrpAdapter) {
        self.adapter = adapter
        accountActive = adapter.accountActivated
        balanceHidden = balanceHiddenManager.balanceHidden

        Publishers.Merge3(
            adapter.xrpKit.accountStatePublisher.map { _ in () },
            adapter.xrpKit.ledgerStatePublisher.map { _ in () },
            adapter.xrpKit.trustLinesPublisher.map { _ in () }
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in self?.sync() }
        .store(in: &cancellables)

        balanceHiddenManager.balanceHiddenObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.balanceHidden = $0 })
            .disposed(by: disposeBag)

        sync()
    }

    // the reserve is a property of a funded account: nothing is locked before the first deposit
    private func sync() {
        accountActive = adapter.accountActivated
        reserveInfo = accountActive ? adapter.reserveInfo : nil
    }
}
