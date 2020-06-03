import UIKit
import ActionSheet
import ThemeKit

class NoAccountViewController: ThemeActionSheetController {
    private let delegate: INoAccountViewDelegate

    private let titleView = BottomSheetTitleView()
    private let descriptionLabel = UILabel()
    private let createButton = ThemeButton()
    private let restoreButton = ThemeButton()

    init(delegate: INoAccountViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.onTapClose = { [weak self] in
            self?.delegate.onTapClose()
        }

        view.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(titleView.snp.bottom).offset(CGFloat.margin3x)
        }

        descriptionLabel.font = .subhead2
        descriptionLabel.textColor = .themeGray
        descriptionLabel.numberOfLines = 0

        view.addSubview(createButton)
        createButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(descriptionLabel.snp.bottom).offset(CGFloat.margin6x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        createButton.apply(style: .primaryYellow)
        createButton.setTitle("manage_coins.add_coin.create".localized, for: .normal)
        createButton.addTarget(self, action: #selector(onTapCreate), for: .touchUpInside)

        view.addSubview(restoreButton)
        restoreButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(createButton.snp.bottom).offset(CGFloat.margin4x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin4x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        restoreButton.apply(style: .primaryGray)
        restoreButton.setTitle("manage_coins.add_coin.restore".localized, for: .normal)
        restoreButton.addTarget(self, action: #selector(onTapRestore), for: .touchUpInside)

        delegate.onLoad()
    }

    @objc private func onTapCreate() {
        delegate.onTapCreate()
    }

    @objc private func onTapRestore() {
        delegate.onTapRestore()
    }

}

extension NoAccountViewController: INoAccountView {

    func set(viewItem: NoAccountModule.ViewItem) {
        titleView.bind(
                title: "manage_coins.add_coin.title".localized(viewItem.coinTitle),
                subtitle: "manage_coins.add_coin.subtitle".localized(viewItem.accountTypeTitle),
                image: .image(coinCode: viewItem.coinCode, blockchainType: viewItem.blockchainType)
        )

        descriptionLabel.text = "manage_coins.add_coin.text.set_up".localized(viewItem.accountTypeTitle, viewItem.coinTitle) +
                "\n\n" +
                (viewItem.createEnabled ? "manage_coins.add_coin.text.create_or_restore".localized(viewItem.accountTypeTitle) : "manage_coins.add_coin.text.create_only".localized(viewItem.accountTypeTitle)) +
                "\n\n" +
                "manage_coins.add_coin.text.tokens".localized(viewItem.coinCodes)

        createButton.snp.remakeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(descriptionLabel.snp.bottom).offset(viewItem.createEnabled ? CGFloat.margin6x : CGFloat.margin2x)
            maker.height.equalTo(viewItem.createEnabled ? CGFloat.heightButton : 0)
        }
    }

    func show(error: Error) {
        HudHelper.instance.showError(title: error.smartDescription)
    }

    func showSuccess() {
        HudHelper.instance.showSuccess()
    }

}
