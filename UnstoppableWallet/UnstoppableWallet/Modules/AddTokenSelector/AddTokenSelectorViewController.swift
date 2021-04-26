import UIKit
import ActionSheet
import ThemeKit
import ComponentKit

class AddTokenSelectorViewController: ThemeActionSheetController {
    private let delegate: IAddTokenSelectorViewDelegate

    private let titleView = BottomSheetTitleView()
    private let erc20Button = ThemeButton()
    private let bep20Button = ThemeButton()
    private let bep2Button = ThemeButton()

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
                image: UIImage(named: "circle_plus_24"),
                tintColor: .themeGray
        )

        titleView.onTapClose = { [weak self] in
            self?.delegate.onTapClose()
        }

        view.addSubview(erc20Button)
        erc20Button.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(titleView.snp.bottom).offset(CGFloat.margin16)
            maker.height.equalTo(CGFloat.heightButton)
        }

        erc20Button.apply(style: .primaryGray)
        erc20Button.setTitle("add_token_selector.erc20_token".localized, for: .normal)
        erc20Button.addTarget(self, action: #selector(onTapErc20), for: .touchUpInside)

        view.addSubview(bep20Button)
        bep20Button.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(erc20Button.snp.bottom).offset(CGFloat.margin16)
            maker.height.equalTo(CGFloat.heightButton)
        }

        bep20Button.apply(style: .primaryGray)
        bep20Button.setTitle("add_token_selector.bep20_token".localized, for: .normal)
        bep20Button.addTarget(self, action: #selector(onTapBep20), for: .touchUpInside)

        view.addSubview(bep2Button)
        bep2Button.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(bep20Button.snp.bottom).offset(CGFloat.margin16)
            maker.bottom.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(CGFloat.heightButton)
        }

        bep2Button.apply(style: .primaryGray)
        bep2Button.setTitle("add_token_selector.bep2_token".localized, for: .normal)
        bep2Button.addTarget(self, action: #selector(onTapBep2), for: .touchUpInside)
    }

    @objc private func onTapErc20() {
        delegate.onTapErc20()
    }

    @objc private func onTapBep20() {
        delegate.onTapBep20()
    }

    @objc private func onTapBep2() {
        delegate.onTapBep2()
    }

}
