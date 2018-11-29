import UIKit
import GrouviHUD

class BlurManager {
    private let blurView = CustomIntensityVisualEffectView(effect: UIBlurEffect(style: .light), intensity: 0.4)

    private let lockManager: ILockManager

    init(lockManager: ILockManager) {
        self.lockManager = lockManager
    }

    private func show() {
        let window = UIApplication.shared.keyWindow
        let frame = window?.frame ?? UIScreen.main.bounds
        blurView.alpha = 1
        blurView.frame = frame
        window?.addSubview(self.blurView)
    }

    private func hide() {
        UIView.animate(withDuration: 0.1, animations: {
            self.blurView.alpha = 0.0
        }, completion: { _ in
            self.blurView.removeFromSuperview()
        })
    }

}

extension BlurManager: IBlurManager {

    func willResignActive() {
        if !lockManager.isLocked && !lockManager.denyLocking {
            show()
        }
    }

    func didBecomeActive() {
        hide()
    }

}
