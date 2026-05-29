import Combine
import Foundation
import RxSwift

class BitcoinWalletTokenViewModel: ObservableObject {
    private let balanceHiddenManager = Core.shared.balanceHiddenManager
    private let adapter: BitcoinBaseAdapter
    private let disposeBag = DisposeBag()

    @Published var bitcoinBalanceData: BitcoinBaseAdapter.BitcoinBalanceData
    @Published var balanceHidden: Bool

    init(adapter: BitcoinBaseAdapter) {
        self.adapter = adapter
        bitcoinBalanceData = adapter.bitcoinBalanceData
        balanceHidden = balanceHiddenManager.balanceHidden

        adapter.bitcoinBalanceDataObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.bitcoinBalanceData = $0 })
            .disposed(by: disposeBag)

        balanceHiddenManager.balanceHiddenObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.balanceHidden = $0
            })
            .disposed(by: disposeBag)
    }
}
