import UIKit
import ThemeKit
import RxSwift
import RxCocoa

class MainViewController: ThemeTabBarController {
    private let disposeBag = DisposeBag()

    private let viewModel: MainViewModel

    init(viewModel: MainViewModel, viewControllers: [UIViewController], selectedIndex: Int) {
        self.viewModel = viewModel

        super.init()

        self.viewControllers = viewControllers
        self.selectedIndex = selectedIndex

        viewModel.settingsBadgeDriver
                .drive(onNext: { [weak self] visible in
                    self?.setSettingsBadge(visible: visible)
                })
                .disposed(by: disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.onLoad()
    }

    private func setSettingsBadge(visible: Bool) {
        guard let viewControllers = viewControllers else {
            return
        }

        for viewController in viewControllers {
            if let navigationController = viewController as? UINavigationController, navigationController.viewControllers.first is MainSettingsViewController {
                viewController.tabBarItem.setDotBadge(visible: visible)
                break
            }
        }
    }

}
