import UIKit
import ThemeKit
import SnapKit
import ComponentKit
import HUD

class WalletHeaderView: UITableViewHeaderFooterView {
    static var height: CGFloat = TextDropDownAndSettingsView.height

    private let sortAddCoinView = TextDropDownAndSettingsView()
    private let watchAccountImage = ImageComponent(size: .iconSize24)

    var onTapSortBy: (() -> ())?
    var onTapAddCoin: (() -> ())?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        backgroundView = UIView()
        backgroundView?.backgroundColor = .themeNavigationBarBackground

        contentView.addSubview(sortAddCoinView)
        sortAddCoinView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(TextDropDownAndSettingsView.height)
        }

        sortAddCoinView.onTapDropDown = { [weak self] in self?.onTapSortBy?() }
        sortAddCoinView.onTapSettings = { [weak self] in self?.onTapAddCoin?() }

        contentView.addSubview(watchAccountImage)
        watchAccountImage.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalTo(sortAddCoinView)
        }

        watchAccountImage.imageView.image = UIImage(named: "binocule_24")?.withTintColor(.themeGray)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(sortBy: String?) {
        sortAddCoinView.set(dropdownTitle: sortBy)
    }

    func bind(controlViewItem: WalletViewModel.ControlViewItem) {
        sortAddCoinView.set(settingsHidden: !controlViewItem.coinManagerVisible)
        watchAccountImage.isHidden = !controlViewItem.watchVisible
    }

}
