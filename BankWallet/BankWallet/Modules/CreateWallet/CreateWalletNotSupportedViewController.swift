import UIKit
import ActionSheet

class CreateWalletNotSupportedViewController: ThemeActionSheetController {
    private let titleView = BottomSheetTitleView()
    private let descriptionView = HighlightedDescriptionView()

    init(coin: Coin, predefinedAccountType: PredefinedAccountType) {
        super.init()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.bind(
                title: "manage_coins.add_coin.title".localized(coin.title),
                subtitle: "manage_coins.add_coin.subtitle".localized(predefinedAccountType.title),
                image: UIImage(coin: coin)?.tinted(with: .themeGray)
        )
        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        view.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(titleView.snp.bottom).offset(CGFloat.margin3x)
        }

        descriptionView.bind(text: "error.cant_create_wallet".localized(predefinedAccountType.title))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
