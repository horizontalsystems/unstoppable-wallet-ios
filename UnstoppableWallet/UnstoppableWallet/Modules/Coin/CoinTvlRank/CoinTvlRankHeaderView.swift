import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class CoinTvlRankHeaderView: UITableViewHeaderFooterView {
    static let height: CGFloat = .heightSingleLineCell

    private let filterButton = ThemeButton()
    private let sortButton = ThemeButton()

    var onTapFilterField: (() -> ())?
    var onTapSortField: (() -> ())?

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

        contentView.addSubview(filterButton)
        filterButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.top.bottom.equalToSuperview()
        }

        filterButton.apply(style: .secondaryTransparentIcon)
        filterButton.setImage(UIImage(named: "arrow_small_down_20"), for: .normal)
        filterButton.setImageTintColor(.themeGray, for: .normal)
        filterButton.setImageTintColor(.themeGray50, for: .highlighted)

        filterButton.addTarget(self, action: #selector(tapFilterField), for: .touchUpInside)

        contentView.addSubview(sortButton)
        sortButton.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview()
            maker.top.bottom.equalToSuperview()
        }

        sortButton.apply(style: .secondaryTransparentIcon)
        sortButton.setImage(UIImage(named: "arrow_small_down_20"), for: .normal)
        sortButton.setImageTintColor(.themeGray, for: .normal)
        sortButton.setImageTintColor(.themeGray50, for: .highlighted)

        sortButton.addTarget(self, action: #selector(tapSortField), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func tapFilterField() {
        onTapFilterField?()
    }

    @objc private func tapSortField() {
        onTapSortField?()
    }

}

extension CoinTvlRankHeaderView {

    func setFilter(title: String) {
        filterButton.setTitle(title, for: .normal)
    }

    func setSortingField(title: String) {
        sortButton.setTitle(title, for: .normal)
    }

}
