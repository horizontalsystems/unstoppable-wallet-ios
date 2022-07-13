import UIKit
import ThemeKit
import ComponentKit

class WalletConnectWatchAccountViewController: ThemeActionSheetController {
    private weak var sourceViewController: UIViewController?

    init(sourceViewController: UIViewController?) {
        self.sourceViewController = sourceViewController

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let titleView = BottomSheetTitleView()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.title = "Wallet Connect"
        titleView.image = UIImage(named: "wallet_connect_24")?.withTintColor(.themeJacob)
        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        let descriptionView = HighlightedDescriptionView()

        view.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(titleView.snp.bottom)
        }

        descriptionView.text = "wallet_connect.watch_account.description".localized

        let switchButton = ThemeButton()

        view.addSubview(switchButton)
        switchButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalTo(descriptionView.snp.bottom).offset(CGFloat.margin24)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin24)
            maker.height.equalTo(CGFloat.heightButton)
        }

        switchButton.apply(style: .primaryYellow)
        switchButton.setTitle("wallet_connect.watch_account.switch".localized, for: .normal)
        switchButton.addTarget(self, action: #selector(onTapSwitchButton), for: .touchUpInside)
    }

    @objc private func onTapSwitchButton() {
        dismiss(animated: true) { [weak self] in
            self?.sourceViewController?.present(SwitchAccountModule.viewController(), animated: true)
        }
    }

}
