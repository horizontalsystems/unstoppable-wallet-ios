import UIKit
import ThemeKit
import SnapKit
import ComponentKit
import HUD

class WalletHeaderView: UITableViewHeaderFooterView {
    private static let bottomMargin: CGFloat = .margin4
    static var height: CGFloat = HeaderAmountView.height + TextDropDownAndSettingsView.height + bottomMargin

    private let amountView = HeaderAmountView()
    private let sortAddCoinView = TextDropDownAndSettingsView()
    private let addressButton = SecondaryButton()

    private var currentAddress: String?

    var onTapSortBy: (() -> ())?
    var onTapAddCoin: (() -> ())?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        backgroundView = UIView()
        backgroundView?.backgroundColor = .themeNavigationBarBackground

        contentView.addSubview(amountView)
        amountView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        let separatorView = UIView()

        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(amountView.snp.bottom)
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        separatorView.backgroundColor = .themeSteel10

        contentView.addSubview(sortAddCoinView)
        sortAddCoinView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(amountView.snp.bottom)
            maker.height.equalTo(TextDropDownAndSettingsView.height)
        }

        sortAddCoinView.onTapDropDown = { [weak self] in self?.onTapSortBy?() }
        sortAddCoinView.onTapSettings = { [weak self] in self?.onTapAddCoin?() }

        contentView.addSubview(addressButton)
        addressButton.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalTo(sortAddCoinView)
        }

        addressButton.set(style: .default)
        addressButton.addTarget(self, action: #selector(onTapAddressButton), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapAddressButton() {
        guard let address = currentAddress else {
            return
        }

        CopyHelper.copyAndNotify(value: address)
    }

    var onTapAmount: (() -> ())? {
        get { amountView.onTapAmount }
        set { amountView.onTapAmount = newValue }
    }

    var onTapConvertedAmount: (() -> ())? {
        get { amountView.onTapConvertedAmount }
        set { amountView.onTapConvertedAmount = newValue }
    }

    func bind(viewItem: WalletViewModel.HeaderViewItem, sortBy: String?) {
        amountView.set(amountText: viewItem.amount, expired: viewItem.amountExpired)
        amountView.set(convertedAmountText: viewItem.convertedValue, expired: viewItem.convertedValueExpired)

        sortAddCoinView.bind(dropdownTitle: sortBy, settingsHidden: viewItem.manageWalletsHidden)

        if let address = viewItem.address {
            addressButton.isHidden = false
            addressButton.setTitle(address.shortened, for: .normal)
            currentAddress = address
        } else {
            addressButton.isHidden = true
        }
    }

}
