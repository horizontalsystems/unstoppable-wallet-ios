import SwiftUI

class CoverManager {
    var windowScene: UIWindowScene?
    private var window: UIWindow?

    private let lockManager: LockManager

    init(lockManager: LockManager) {
        self.lockManager = lockManager
    }

    func willResignActive() {
        guard let windowScene, window == nil, !lockManager.isLocked else {
            return
        }

        let window = UIWindow(windowScene: windowScene)
        window.windowLevel = UIWindow.Level.alert - 2
        window.isHidden = false
        window.alpha = 0

        let hostingController = UIHostingController(rootView: CoverView())
        window.rootViewController = hostingController

        UIView.animate(withDuration: 0.15) {
            window.alpha = 1
        }

        self.window = window
    }

    func didBecomeActive() {
        guard window != nil else {
            return
        }

        UIView.animate(withDuration: 0.15, animations: {
            self.window?.alpha = 0
        }) { _ in
            self.window = nil
        }
    }

    func willEnterForeground() {
        window = nil
    }
}
