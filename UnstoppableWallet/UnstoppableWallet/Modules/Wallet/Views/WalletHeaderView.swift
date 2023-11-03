import ComponentKit
import SnapKit
import ThemeKit
import UIKit

class WalletHeaderView: UITableViewHeaderFooterView {
    static var height: CGFloat = .heightSingleLineCell

    private let sortByButton = SecondaryButton()

    private let stackView = UIStackView()
    private let settingsButton = SecondaryCircleButton()
    private let watchAccountImage = ImageComponent(size: .iconSize24)

    var onTapSortBy: (() -> Void)?
    var onTapSettings: (() -> Void)?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        backgroundView = UIView()
        backgroundView?.backgroundColor = .themeNavigationBarBackground

        let separatorView = UIView()
        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(CGFloat.heightOneDp)
        }

        separatorView.backgroundColor = .themeSteel20

        addSubview(sortByButton)
        sortByButton.snp.makeConstraints { maker in
            maker.leading.centerY.equalToSuperview()
        }

        sortByButton.set(style: .transparent, image: UIImage(named: "arrow_small_down_20"))
        sortByButton.addTarget(self, action: #selector(onTapSortByButton), for: .touchUpInside)

        addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
        }

        stackView.axis = .horizontal
        stackView.spacing = .margin16

        stackView.addArrangedSubview(watchAccountImage)
        watchAccountImage.imageView.image = UIImage(named: "binocule_24")?.withTintColor(.themeGray)

        stackView.addArrangedSubview(settingsButton)
        settingsButton.set(image: UIImage(named: "manage_2_20"))
        settingsButton.addTarget(self, action: #selector(onTapSettingsButton), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapSortByButton() {
        onTapSortBy?()
    }

    @objc private func onTapSettingsButton() {
        onTapSettings?()
    }

    func set(sortByTitle: String?) {
        sortByButton.setTitle(sortByTitle, for: .normal)
    }

    func set(controlViewItem: WalletViewModel.ControlViewItem) {
        watchAccountImage.isHidden = !controlViewItem.watchVisible
        settingsButton.isHidden = !controlViewItem.coinManagerVisible
    }
}
