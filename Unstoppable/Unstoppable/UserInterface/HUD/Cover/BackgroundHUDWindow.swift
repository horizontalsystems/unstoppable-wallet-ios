import Foundation
import UIKit

class BackgroundHUDWindow: HUDWindow {
    private(set) var coverView: CoverViewInterface

    init(frame: CGRect, rootController: UIViewController, coverView: CoverViewInterface, level: UIWindow.Level = UIWindow.Level.normal, cornerRadius: CGFloat = 0) {
        self.coverView = coverView
        super.init(frame: frame, rootController: rootController, level: level, cornerRadius: cornerRadius)
    }

    init(windowScene: UIWindowScene, rootController: UIViewController, coverView: CoverViewInterface, level: UIWindow.Level = UIWindow.Level.normal, cornerRadius: CGFloat = 0) {
        self.coverView = coverView
        super.init(windowScene: windowScene, rootController: rootController, level: level, cornerRadius: cornerRadius)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    func set(transparent: Bool) {
        self.transparent = transparent
        coverView.transparent = transparent
    }
}
