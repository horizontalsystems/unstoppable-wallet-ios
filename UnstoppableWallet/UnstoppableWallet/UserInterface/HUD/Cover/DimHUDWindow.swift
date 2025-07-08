import UIKit

class DimHUDWindow: BackgroundHUDWindow {
    private var dimViewController: DimViewController?

    init(windowScene: UIWindowScene, level: Level = UIWindow.Level.normal, config: HUDConfig = HUDConfig(), cornerRadius: CGFloat = 0) {
        let coverView = DimCoverView(withModel: config)

        let dimViewController = DimViewController(coverView: coverView)
        self.dimViewController = dimViewController

        super.init(windowScene: windowScene, rootController: dimViewController, coverView: coverView, level: level, cornerRadius: cornerRadius)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }
}

extension DimHUDWindow {
    var onTap: (() -> Void)? {
        get { dimViewController?.onTap }
        set { dimViewController?.onTap = newValue }
    }
}
