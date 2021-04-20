import UIKit
import UIExtensions
import ThemeKit
import PinKit

class BlurManager {
    private let blurView = CustomIntensityVisualEffectView(effect: UIBlurEffect(style: .light), intensity: 0.4)
    private let hideView = UIView()

    private let pinKit: IPinKit

    init(pinKit: IPinKit) {
        self.pinKit = pinKit
    }

    private func show() {
        hideView.backgroundColor = UIColor.themeBackgroundFromGradient.withAlphaComponent(0.99)

        let window = UIApplication.shared.windows.first { $0.isKeyWindow }
        let frame = window?.frame ?? UIScreen.main.bounds

        if UIAccessibility.isReduceTransparencyEnabled {
            hideView.alpha = 1
        } else {
            blurView.alpha = 1
        }

        blurView.frame = frame
        hideView.frame = frame

        window?.addSubview(self.blurView)
        window?.addSubview(self.hideView)
    }

    private func hide() {
        UIView.animate(withDuration: 0.1, animations: {
            self.blurView.alpha = 0
            self.hideView.alpha = 0
        }, completion: { _ in
            self.blurView.removeFromSuperview()
        })
    }

}

extension BlurManager: IBlurManager {

    func willResignActive() {
        if !pinKit.isLocked {
            show()
        }
    }

    func didBecomeActive() {
        hide()
    }

}
