import UIKit
import GrouviHUD

class BlurView {
    let blurView = CustomIntensityVisualEffectView(effect: UIBlurEffect(style: .light), intensity: 0.4)

    func show() {
        let window = UIApplication.shared.keyWindow
        let frame = window?.frame ?? UIScreen.main.bounds
        blurView.alpha = 1
        blurView.frame = frame
        window?.addSubview(self.blurView)
    }

    func hide(slow: Bool) {
        UIView.animate(withDuration: slow ? 1 : 0.1, animations: {
            self.blurView.alpha = 0.0
        }, completion: { _ in
            self.blurView.removeFromSuperview()
        })
    }

}
