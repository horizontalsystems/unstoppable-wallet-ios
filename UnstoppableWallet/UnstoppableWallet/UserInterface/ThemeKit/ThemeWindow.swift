import Combine
import UIKit

open class ThemeWindow: UIWindow {
    private var cancellables = Set<AnyCancellable>()

    override public init(frame: CGRect) {
        super.init(frame: frame)

        update(themeMode: ThemeManager.shared.themeMode)

        commonInit()
    }

    override public init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)

        commonInit()
    }

    private func commonInit() {
        update(themeMode: ThemeManager.shared.themeMode)

        ThemeManager.shared.$themeMode
            .sink { [weak self] themeMode in
                self?.update(themeMode: themeMode)
            }
            .store(in: &cancellables)
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func update(themeMode: ThemeMode) {
        UIView.transition(with: self, duration: 0.5, options: .transitionCrossDissolve, animations: {
            switch themeMode {
            case .system:
                self.overrideUserInterfaceStyle = .unspecified
            case .dark:
                self.overrideUserInterfaceStyle = .dark
            case .light:
                self.overrideUserInterfaceStyle = .light
            }
        }, completion: nil)
    }
}
