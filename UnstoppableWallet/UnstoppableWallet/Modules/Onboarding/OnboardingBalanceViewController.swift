import UIKit
import ThemeKit
import SnapKit

class OnboardingBalanceViewController: ThemeViewController {

    init() {
        super.init()

        tabBarItem = UITabBarItem(title: "balance.tab_bar_item".localized, image: UIImage(named: "filled_wallet_24"), tag: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "balance.title".localized

        let cautionWrapper = UIView()

        view.addSubview(cautionWrapper)
        cautionWrapper.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(view.safeAreaLayoutGuide)
        }

        let cautionView = CircleCautionView()

        cautionWrapper.addSubview(cautionView)
        cautionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin48)
            maker.centerY.equalToSuperview()
        }

        cautionView.image = UIImage(named: "wallet_48")
        cautionView.text = "onboarding.balance.description".localized

        let createButton = ThemeButton()

        view.addSubview(createButton)
        createButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalTo(cautionWrapper.snp.bottom)
            maker.height.equalTo(CGFloat.heightButton)
        }

        createButton.apply(style: .primaryYellow)
        createButton.setTitle("onboarding.balance.create".localized, for: .normal)
        createButton.addTarget(self, action: #selector(didTapCreate), for: .touchUpInside)

        let restoreButton = ThemeButton()

        view.addSubview(restoreButton)
        restoreButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalTo(createButton.snp.bottom).offset(CGFloat.margin16)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin32)
            maker.height.equalTo(CGFloat.heightButton)
        }

        restoreButton.apply(style: .primaryGray)
        restoreButton.setTitle("onboarding.balance.restore".localized, for: .normal)
        restoreButton.addTarget(self, action: #selector(didTapRestore), for: .touchUpInside)
    }

    @objc func didTapCreate() {
        CreateWalletModule.start(mode: .present(viewController: self))
    }

    @objc func didTapRestore() {
        RestoreModule.start(mode: .present(viewController: self))
    }

}
