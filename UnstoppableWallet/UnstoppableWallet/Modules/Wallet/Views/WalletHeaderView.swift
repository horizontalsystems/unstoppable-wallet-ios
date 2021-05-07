import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class WalletHeaderView: UICollectionReusableView {
    static let height: CGFloat = 84

    private let amountButton = UIButton()
    private let sortButton = ThemeButton()
    private let addCoinButton = ThemeButton()

    var onTapAmount: (() -> ())?
    var onTapSortBy: (() -> ())?
    var onTapAddCoin: (() -> ())?

    override init(frame: CGRect) {
        super.init(frame: frame)

        clipsToBounds = true
        tintColor = .clear
        preservesSuperviewLayoutMargins = true
        backgroundColor = .themeNavigationBarBackground

        addSubview(amountButton)
        amountButton.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(40)
        }

        amountButton.contentHorizontalAlignment = .leading
        amountButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: .margin16, bottom: 0, right: .margin16)
        amountButton.titleLabel?.font = .title3
        amountButton.addTarget(self, action: #selector(onTapAmountButton), for: .touchUpInside)

        let separatorView = UIView()

        addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(amountButton.snp.bottom)
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        separatorView.backgroundColor = .themeSteel10

        addSubview(sortButton)
        sortButton.snp.makeConstraints { maker in
            maker.leading.bottom.equalToSuperview()
            maker.top.equalTo(amountButton.snp.bottom)
        }

        sortButton.apply(style: .secondaryTransparentIcon)
        sortButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        sortButton.setTitle("balance.sort_by".localized, for: .normal)
        sortButton.setImageTintColor(.themeGray, for: .normal)
        sortButton.setImageTintColor(.themeGray50, for: .highlighted)
        sortButton.setImage(UIImage(named: "arrow_small_down_20"), for: .normal)

        sortButton.addTarget(self, action: #selector(onTapSortByButton), for: .touchUpInside)

        addSubview(addCoinButton)
        addCoinButton.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalTo(sortButton)
        }

        addCoinButton.apply(style: .tertiary)
        addCoinButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        addCoinButton.setTitle("balance.add_coin".localized, for: .normal)
        addCoinButton.addTarget(self, action: #selector(onTapAddCoinButton), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(viewItem: WalletViewModel.HeaderViewItem) {
        amountButton.setTitle(viewItem.amount, for: .normal)
        amountButton.setTitleColor(viewItem.amountExpired ? .themeYellow50 : .themeJacob, for: .normal)
    }

    @objc private func onTapAmountButton() {
        onTapAmount?()
    }

    @objc private func onTapSortByButton() {
        onTapSortBy?()
    }

    @objc private func onTapAddCoinButton() {
        onTapAddCoin?()
    }

}
