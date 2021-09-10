import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class WalletHeaderView: UITableViewHeaderFooterView {
    private static let amountHeight: CGFloat = 40
    private static let sortHeight: CGFloat = .heightSingleLineCell
    private static let bottomMargin: CGFloat = .margin4

    private let amountButton = UIButton()
    private let sortButton = ThemeButton()
    private let addCoinButton = ThemeButton()

    var onTapAmount: (() -> ())?
    var onTapSortBy: (() -> ())?
    var onTapAddCoin: (() -> ())?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        backgroundView = UIView()

        let wrapperView = UIView()

        contentView.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(Self.amountHeight + Self.sortHeight)
        }

        wrapperView.backgroundColor = .themeNavigationBarBackground

        wrapperView.addSubview(amountButton)
        amountButton.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(Self.amountHeight)
        }

        amountButton.contentHorizontalAlignment = .leading
        amountButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: .margin16, bottom: 0, right: .margin16)
        amountButton.titleLabel?.font = .title3
        amountButton.addTarget(self, action: #selector(onTapAmountButton), for: .touchUpInside)

        let separatorView = UIView()

        wrapperView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(amountButton.snp.bottom)
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        separatorView.backgroundColor = .themeSteel10

        wrapperView.addSubview(sortButton)
        sortButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.top.equalTo(amountButton.snp.bottom)
            maker.height.equalTo(Self.sortHeight)
        }

        sortButton.apply(style: .secondaryTransparentIcon)
        sortButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        sortButton.setTitle("balance.sort_by".localized, for: .normal)
        sortButton.setImageTintColor(.themeGray, for: .normal)
        sortButton.setImageTintColor(.themeGray50, for: .highlighted)
        sortButton.setImage(UIImage(named: "arrow_small_down_20"), for: .normal)

        sortButton.addTarget(self, action: #selector(onTapSortByButton), for: .touchUpInside)

        wrapperView.addSubview(addCoinButton)
        addCoinButton.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalTo(sortButton)
        }

        addCoinButton.apply(style: .secondaryIcon)
        addCoinButton.apply(secondaryIconImage: UIImage(named: "manage_2_20"))
        addCoinButton.addTarget(self, action: #selector(onTapAddCoinButton), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

    func bind(viewItem: WalletViewModel.HeaderViewItem) {
        amountButton.setTitle(viewItem.amount, for: .normal)
        amountButton.setTitleColor(viewItem.amountExpired ? .themeYellow50 : .themeJacob, for: .normal)
    }

    static var height: CGFloat {
        amountHeight + sortHeight + bottomMargin
    }

}
