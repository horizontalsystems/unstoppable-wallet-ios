import UIKit
import ActionSheet
import ThemeKit

class AddTokenSelectorViewController: ThemeActionSheetController {
    private let delegate: IAddTokenSelectorViewDelegate

    private let titleView = BottomSheetTitleView()
    private let erc20Button = ThemeButton()
    private let binanceButton = ThemeButton()

    init(delegate: IAddTokenSelectorViewDelegate) {
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

        titleView.bind(
                title: "add_token_selector.choose_blockchain".localized,
                subtitle: "add_token_selector.add_token".localized,
                image: UIImage(named: "circle_plus_24")?.tinted(with: .themeGray)
        )

        titleView.onTapClose = { [weak self] in
            self?.delegate.onTapClose()
        }

        view.addSubview(erc20Button)
        erc20Button.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(titleView.snp.bottom).offset(CGFloat.margin4x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        erc20Button.apply(style: .primaryGray)
        erc20Button.setTitle("add_token_selector.erc20_token".localized, for: .normal)
        erc20Button.addTarget(self, action: #selector(onTapErc20), for: .touchUpInside)

        view.addSubview(binanceButton)
        binanceButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(erc20Button.snp.bottom).offset(CGFloat.margin4x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin4x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        binanceButton.apply(style: .primaryGray)
        binanceButton.setTitle("add_token_selector.binance_token".localized, for: .normal)
        binanceButton.addTarget(self, action: #selector(onTapBinance), for: .touchUpInside)
    }

    @objc private func onTapErc20() {
        delegate.onTapErc20()
    }

    @objc private func onTapBinance() {
        delegate.onTapBinance()
    }

}
