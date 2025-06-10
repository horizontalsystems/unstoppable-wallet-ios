import Combine
import Foundation
import RxSwift
import StellarKit

class StellarWalletTokenViewModel: ObservableObject {
    private let balanceHiddenManager = App.shared.balanceHiddenManager
    private let stellarKit: StellarKit.Kit
    private let asset: Asset

    private var cancellables = Set<AnyCancellable>()
    private let disposeBag = DisposeBag()

    @Published var lockInfo: LockInfo?
    @Published var balanceHidden: Bool

    init(stellarKit: StellarKit.Kit, asset: Asset) {
        self.stellarKit = stellarKit
        self.asset = asset
        balanceHidden = balanceHiddenManager.balanceHidden

        stellarKit.accountPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncLockInfo()
            }
            .store(in: &cancellables)

        balanceHiddenManager.balanceHiddenObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.balanceHidden = $0
            })
            .disposed(by: disposeBag)

        syncLockInfo()
    }

    private func syncLockInfo() {
        if let account = stellarKit.account, asset.isNative {
            lockInfo = LockInfo(amount: account.lockedBalance, assets: Array(account.assetBalanceMap.keys).filter { !$0.isNative }.map(\.code).sorted())
        } else {
            lockInfo = nil
        }
    }
}

extension StellarWalletTokenViewModel {
    struct LockInfo {
        let amount: Decimal
        let assets: [String]
    }
}
