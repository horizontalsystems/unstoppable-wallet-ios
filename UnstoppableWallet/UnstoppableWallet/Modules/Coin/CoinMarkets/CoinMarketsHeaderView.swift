import UIKit
import UIExtensions
import ThemeKit
import SnapKit
import ComponentKit

class CoinMarketsHeaderView: UITableViewHeaderFooterView {
    static let height: CGFloat = .heightSingleLineCell

    private let sortTypeButton = ThemeButton()
    private let volumeTypeView = SelectorButton()

    var onTapSortType: (() -> ())?
    var onSelectVolumeType: ((Int) -> ())?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        backgroundView = UIView()
        backgroundView?.backgroundColor = .themeNavigationBarBackground

        let separatorView = UIView()
        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        separatorView.backgroundColor = .themeSteel20

        contentView.addSubview(sortTypeButton)
        sortTypeButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
            maker.size.equalTo(28)
        }

        sortTypeButton.apply(style: .secondaryIcon)
        sortTypeButton.addTarget(self, action: #selector(tapSortTypeButton), for: .touchUpInside)

        contentView.addSubview(volumeTypeView)
        volumeTypeView.snp.makeConstraints { maker in
            maker.leading.equalTo(sortTypeButton.snp.trailing).priority(.high)
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
            maker.height.equalTo(28)
        }

        volumeTypeView.onSelect = { [weak self] index in
            self?.onSelectVolumeType?(index)
        }

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func tapSortTypeButton() {
        onTapSortType?()
    }

}

extension CoinMarketsHeaderView {

    func setSort(descending: Bool) {
        let imageName = descending ? "arrow_medium_2_down_20" : "arrow_medium_2_up_20"
        sortTypeButton.setImage(UIImage(named: imageName), for: .normal)
    }

    func set(volumeTypes: [String]) {
        volumeTypeView.set(items: volumeTypes)
    }

    func setVolumeType(index: Int) {
        volumeTypeView.setSelected(index: index)
    }

}
