import UIKit
import ThemeKit
import SnapKit
import ComponentKit
import HUD

class WalletHeaderView: UITableViewHeaderFooterView {
    private static let amountHeight: CGFloat = 40
    private static let bottomMargin: CGFloat = .margin4

    private let amountButton = UIButton()
    private let sortAddCoinView = TextDropDownAndSettingsView()
    private let addressButton = ThemeButton()

    private var currentAddress: String?

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
            maker.height.equalTo(Self.amountHeight + TextDropDownAndSettingsView.height)
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

        wrapperView.addSubview(sortAddCoinView)
        sortAddCoinView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(amountButton.snp.bottom)
            maker.height.equalTo(TextDropDownAndSettingsView.height)
        }

        sortAddCoinView.onTapDropDown = { [weak self] in self?.onTapSortBy?() }
        sortAddCoinView.onTapSettings = { [weak self] in self?.onTapAddCoin?() }

        wrapperView.addSubview(addressButton)
        addressButton.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalTo(sortAddCoinView)
        }

        addressButton.apply(style: .secondaryDefault)
        addressButton.addTarget(self, action: #selector(onTapAddressButton), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapAmountButton() {
        onTapAmount?()
    }

    @objc private func onTapAddressButton() {
        guard let address = currentAddress else {
            return
        }

        CopyHelper.copyAndNotify(value: address)
    }

    func bind(viewItem: WalletViewModel.HeaderViewItem, sortBy: String?) {
        amountButton.setTitle(viewItem.amount, for: .normal)
        amountButton.setTitleColor(viewItem.amountExpired ? .themeYellow50 : .themeJacob, for: .normal)

        sortAddCoinView.bind(dropdownTitle: sortBy, settingsHidden: viewItem.manageWalletsHidden)

        if let address = viewItem.address {
            addressButton.isHidden = false
            addressButton.setTitle(address.shortenedAddress, for: .normal)
            currentAddress = address
        } else {
            addressButton.isHidden = true
        }
    }

    static var height: CGFloat {
        amountHeight + TextDropDownAndSettingsView.height + bottomMargin
    }

}
