import SnapKit
import UIKit

class HUDWindow: ThemeWindow {
    override var frame: CGRect {
        didSet { // IMPORTANT. When window is square safeAreaInsets in willTransition controller rotate not changing!
            if abs(frame.height - frame.width) < 1 / UIScreen.main.scale {
                frame.size = CGSize(width: frame.width, height: frame.height + 1 / UIScreen.main.scale)
            }
        }
    }

    var transparent: Bool = false
    init(frame: CGRect, rootController: UIViewController, level: UIWindow.Level = UIWindow.Level.normal, cornerRadius _: CGFloat = 0) {
        super.init(frame: frame)

        isHidden = false
        windowLevel = level
//        layer.cornerRadius = cornerRadius
        backgroundColor = .clear
        rootViewController = rootController
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    deinit {
//        print("deinit HUDWindow \(self)")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if transparent {
            return nil
        }

        return super.hitTest(point, with: event)
    }
}
