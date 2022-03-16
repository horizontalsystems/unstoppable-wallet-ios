import Foundation
import StoreKit

class RateAppManager {
    private let minLaunchCount = 5
    private let countdownTimeInterval: TimeInterval = 10
    private let repeatedRequestTimeInterval: TimeInterval = 40 * 24 * 60 * 60 // 40 days

    private let walletManager: WalletManager
    private let adapterManager: AdapterManager
    private let localStorage: LocalStorage

    private var isCountdownAllowed = false
    private var isCountdownPassed = false
    private var isRequestAllowed = false
    private var isOnBalancePage = false

    private var timer: Timer?

    init(walletManager: WalletManager, adapterManager: AdapterManager, localStorage: LocalStorage) {
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.localStorage = localStorage
    }

    private func onCountdownPass() {
        let hasBalance = walletManager.activeWallets.contains { wallet in
            guard let adapter = adapterManager.balanceAdapter(for: wallet) else {
                return false
            }

            return adapter.balanceData.balance > 0
        }

        guard hasBalance else {
            return
        }

        isRequestAllowed = true

        showIfAllowed()
    }

    private func showIfAllowed() {
        guard isRequestAllowed && isOnBalancePage else {
            return
        }

        show()
    }

    private func show() {
        SKStoreReviewController.requestReview()

        localStorage.rateAppLastRequestDate = Date()
        isRequestAllowed = false
    }

}

extension RateAppManager {

    func onBalancePageAppear() {
        isOnBalancePage = true
        showIfAllowed()
    }

    func onBalancePageDisappear() {
        isOnBalancePage = false
    }

    func onLaunch() {
        if let lastRequestDate = localStorage.rateAppLastRequestDate, Date().timeIntervalSince1970 - lastRequestDate.timeIntervalSince1970 < repeatedRequestTimeInterval {
            return
        }

        let launchCount = localStorage.appLaunchCount

        guard launchCount >= minLaunchCount else {
            localStorage.appLaunchCount = launchCount + 1
            return
        }

        isCountdownAllowed = true
    }

    func onBecomeActive() {
        guard isCountdownAllowed, !isCountdownPassed else { return }

        timer = Timer.scheduledTimer(withTimeInterval: countdownTimeInterval, repeats: false) { [weak self] _ in
            self?.isCountdownPassed = true
            self?.onCountdownPass()
        }
    }

    func onResignActive() {
        timer?.invalidate()
    }

    func forceShow() {
        isCountdownAllowed = false
        timer?.invalidate()

        show()
    }

}
