import Foundation
import RxSwift

class RateSyncer {
    private let disposeBag = DisposeBag()

    private let rateManager: IRateManager
    private let reachabilityManager: IReachabilityManager
    private let walletManager: IWalletManager
    private var timer: ITimer

    init(rateManager: IRateManager, reachabilityManager: IReachabilityManager, walletManager: IWalletManager, timer: ITimer) {
        self.rateManager = rateManager
        self.reachabilityManager = reachabilityManager
        self.walletManager = walletManager
        self.timer = timer

        self.timer.delegate = self

        rateManager.updateRates()

        walletManager.walletsSubject
                .subscribe(onNext: { _ in
                    rateManager.updateRates()
                })
                .disposed(by: disposeBag)

        reachabilityManager.subject
                .subscribe(onNext: { connected in
                    if connected {
                        rateManager.updateRates()
                    }
                })
                .disposed(by: disposeBag)
    }

}

extension RateSyncer: ITimerDelegate {

    func onFire() {
        rateManager.updateRates()
    }

}
