import UIKit
import ThemeKit
import ComponentKit

class WalletConnectNoAccountViewController: ThemeActionSheetController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let titleView = BottomSheetTitleView()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.bind(
                title: "Wallet Connect",
                subtitle: "alert".localized,
                image: UIImage(named: "wallet_connect_24"),
                tintColor: .themeJacob
        )
        titleView.onTapClose = { [weak self] in self?.dismiss(animated: true) }

        let descriptionView = HighlightedDescriptionView()

        view.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(titleView.snp.bottom).offset(CGFloat.margin12)
        }

        descriptionView.text = "wallet_connect.no_account.description".localized

        let button = ThemeButton()

        view.addSubview(button)
        button.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(descriptionView.snp.bottom).offset(CGFloat.margin16)
            maker.height.equalTo(CGFloat.heightButton)
        }

        button.apply(style: .primaryYellow)
        button.setTitle("wallet_connect.no_account.i_understand".localized, for: .normal)
        button.addTarget(self, action: #selector(onTapButton), for: .touchUpInside)
    }

    @objc private func onTapButton() {
        dismiss(animated: true)
    }

}
