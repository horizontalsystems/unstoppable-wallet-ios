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

    @Published var zcashBalanceData: ZcashAdapter.ZcashBalanceData
    @Published var balanceHidden: Bool

    init(adapter: ZcashAdapter, wallet: Wallet) {
        self.adapter = adapter
        self.wallet = wallet
        zcashBalanceData = adapter.zcashBalanceData
        balanceHidden = balanceHiddenManager.balanceHidden

        adapter.$zcashBalanceData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.zcashBalanceData = $0 }
            .store(in: &cancellables)

        balanceHiddenManager.balanceHiddenObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.balanceHidden = $0
            })
            .disposed(by: disposeBag)
    }
}
