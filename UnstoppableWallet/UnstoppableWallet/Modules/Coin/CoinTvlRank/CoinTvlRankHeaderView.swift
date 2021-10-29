//import UIKit
//import ThemeKit
//import SnapKit
//import ComponentKit
//
//class CoinTvlRankHeaderView: UITableViewHeaderFooterView {
//    static let height: CGFloat = .heightSingleLineCell
//
//    private let filterButton = ThemeButton()
//    private let sortButton = ThemeButton()
//
//    var onTapFilterField: (() -> ())?
//    var onTapSortField: (() -> ())?
//
//    override init(reuseIdentifier: String?) {
//        super.init(reuseIdentifier: reuseIdentifier)
//
//        backgroundView = UIView()
//        backgroundView?.backgroundColor = .themeNavigationBarBackground
//
//        let separatorView = UIView()
//        contentView.addSubview(separatorView)
//        separatorView.snp.makeConstraints { maker in
//            maker.leading.trailing.equalToSuperview()
//            maker.top.equalToSuperview()
//            maker.height.equalTo(CGFloat.heightOnePixel)
//        }
//
//        separatorView.backgroundColor = .themeSteel20
//
//        contentView.addSubview(filterButton)
//        filterButton.snp.makeConstraints { maker in
//            maker.leading.equalToSuperview()
//            maker.top.bottom.equalToSuperview()
//        }
//
//        filterButton.apply(style: .secondaryTransparentIcon)
//        filterButton.setImage(UIImage(named: "arrow_small_down_20")?.withTintColor(.themeGray), for: .normal)
//        filterButton.setImage(UIImage(named: "arrow_small_down_20")?.withTintColor(.themeGray50), for: .highlighted)
//
//        filterButton.addTarget(self, action: #selector(tapFilterField), for: .touchUpInside)
//
//        contentView.addSubview(sortButton)
//        sortButton.snp.makeConstraints { maker in
//            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
//            maker.centerY.equalToSuperview()
//            maker.size.equalTo(28)
//        }
//
//        sortButton.apply(style: .secondaryIcon)
//        sortButton.addTarget(self, action: #selector(tapSortField), for: .touchUpInside)
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    @objc private func tapFilterField() {
//        onTapFilterField?()
//    }
//
//    @objc private func tapSortField() {
//        onTapSortField?()
//    }
//
//}
//
//extension CoinTvlRankHeaderView {
//
//    func setFilter(title: String) {
//        filterButton.setTitle(title, for: .normal)
//    }
//
//    func setSort(descending: Bool) {
//        let imageName = descending ? "arrow_medium_2_down_20" : "arrow_medium_2_up_20"
//        sortButton.setImage(UIImage(named: imageName), for: .normal)
//    }
//
//}
