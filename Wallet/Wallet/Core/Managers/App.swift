import UIKit
import RxSwift
import GrouviHUD

class App {
    static let shared = App()
    let disposeBag = DisposeBag()
    let lastExitDateKey = "last_exit_date_key"

    var resignActiveSubject = PublishSubject<()>()
    var becomeActiveSubject = PublishSubject<()>()

    var isLocked = false
    let blurView = CustomIntensityVisualEffectView(effect: UIBlurEffect(style: .light), intensity: 0.4)
    let lockTimeout: Double = 3
    var unlockWindow: UIWindow?
    var unlockController: UIViewController?

    init() {
        resignActiveSubject.subscribeAsync(disposeBag: disposeBag, onNext: { [weak self] in
            self?.onResignActive()
        })
        becomeActiveSubject.subscribeAsync(disposeBag: disposeBag, onNext: { [weak self] in
            self?.onBecomeActive()
        })
    }

    func onResignActive() {
        if WordsManager.shared.words != nil, !isLocked {
            let window = UIApplication.shared.keyWindow
            let frame = window?.frame ?? UIScreen.main.bounds
            blurView.alpha = 1
            blurView.frame = frame
            window?.addSubview(self.blurView)
        }
        UserDefaultsStorage.shared.set(Date().timeIntervalSince1970, for: lastExitDateKey)
    }

    func onBecomeActive() {
        lock()
    }

    func lock() {
        let exitTimestamp = UserDefaults.standard.double(forKey: lastExitDateKey)
        let now = Date().timeIntervalSince1970
        let needToLock = now - exitTimestamp > lockTimeout

        let duration = needToLock ? 1 : 0.1
        UIView.animate(withDuration: duration, animations: {
            self.blurView.alpha = 0.0
        }, completion: { _ in
            self.blurView.removeFromSuperview()
        })
        if WordsManager.shared.words != nil, UnlockHelper.shared.isPinned, needToLock, !isLocked {
            isLocked = true
            let controller = PinRouter.unlockPinModule(onUnlock: { [weak self] in
                self?.dismissUnlock()
            })
            unlockController = controller
            unlockWindow = UIWindow(frame: UIScreen.main.bounds)
            controller.view.frame = UIScreen.main.bounds
            unlockWindow?.rootViewController = controller
            unlockWindow?.makeKeyAndVisible()
        }
    }

    func dismissUnlock() {
        UIView.animate(withDuration: 0.3, animations: {
            self.unlockController?.view.frame.origin.y = UIScreen.main.bounds.height
        }, completion: { _ in
            self.unlockController = nil
            self.unlockWindow = nil
            self.isLocked = false
        })
    }

}
