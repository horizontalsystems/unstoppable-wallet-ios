import UIKit
import GrouviHUD

class BlurManager {
    let blurView = CustomIntensityVisualEffectView(effect: UIBlurEffect(style: .light), intensity: 0.4)

    let lockManager: LockManager

    init(lockManager: LockManager) {
        self.lockManager = lockManager
    }

    func willResignActive() {
        if !lockManager.isLocked {
            show()
        }
    }

    func didBecomeActive() {
        hide()
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
