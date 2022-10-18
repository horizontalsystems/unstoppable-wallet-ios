import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class OnboardingBalanceViewController: ThemeViewController {

    override init() {
        super.init()

        tabBarItem = UITabBarItem(title: "balance.tab_bar_item".localized, image: UIImage(named: "filled_wallet_24"), tag: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let placeholderView = PlaceholderView(layoutType: .bottom)

        view.addSubview(placeholderView)
        placeholderView.snp.makeConstraints { maker in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }

        placeholderView.image = UIImage(named: "wallet_48")
        placeholderView.text = "onboarding.balance.description".localized

        placeholderView.addPrimaryButton(
                style: .yellow,
                title: "onboarding.balance.create".localized,
                target: self,
                action: #selector(didTapCreate)
        )

        placeholderView.addPrimaryButton(
                style: .gray,
                title: "onboarding.balance.restore".localized,
                target: self,
                action: #selector(didTapRestore)
        )

        placeholderView.addPrimaryButton(
                style: .transparent,
                title: "onboarding.balance.watch".localized,
                target: self,
                action: #selector(didTapWatch)
        )
    }

    @objc func didTapCreate() {
        let viewController = CreateAccountModule.viewController(sourceViewController: self)
        present(viewController, animated: true)
    }

    @objc func didTapRestore() {
        let viewController = RestoreModule.viewController(sourceViewController: self)
        present(viewController, animated: true)
    }

    @objc func didTapWatch() {
        let viewController = WatchModule.viewController()
        present(viewController, animated: true)
    }

}
