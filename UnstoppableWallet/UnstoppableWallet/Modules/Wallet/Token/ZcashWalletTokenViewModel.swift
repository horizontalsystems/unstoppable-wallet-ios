import Combine
import Foundation
import RxSwift

class ZcashWalletTokenViewModel: ObservableObject {
    private let balanceHiddenManager = Core.shared.balanceHiddenManager
    private let restoreSettingsService = RestoreSettingsService(manager: Core.shared.restoreSettingsManager)
    private let adapter: ZcashAdapter

    private var cancellables = Set<AnyCancellable>()
    private let disposeBag = DisposeBag()

    let wallet: Wallet

    @Published var zCashBalanceData: ZcashBalanceData
    @Published var balanceHidden: Bool

    init(adapter: ZcashAdapter, wallet: Wallet) {
        self.adapter = adapter
        self.wallet = wallet
        zCashBalanceData = adapter.zCashBalanceData
        balanceHidden = balanceHiddenManager.balanceHidden

        adapter.$zCashBalanceData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.zCashBalanceData = $0 }
            .store(in: &cancellables)

        balanceHiddenManager.balanceHiddenObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.balanceHidden = $0
            })
            .disposed(by: disposeBag)
    }
}

extension ZcashWalletTokenViewModel {
    var ownAddress: String? {
        adapter.uAddress?.stringEncoded
    }
}
