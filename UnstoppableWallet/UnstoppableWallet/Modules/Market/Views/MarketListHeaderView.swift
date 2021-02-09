import UIKit
import UIExtensions
import ThemeKit
import SnapKit

class MarketListHeaderView: UITableViewHeaderFooterView {
    static let height: CGFloat = .heightSingleLineCell

    private let fieldSelectionButton = ThemeButton()
    private let marketFieldModeView = MarketFieldModeView()

    var onTapSortField: (() -> ())?
    var onSelect: ((MarketModule.MarketField) -> ())?

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

        contentView.addSubview(fieldSelectionButton)
        fieldSelectionButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.top.bottom.equalToSuperview()
        }

        fieldSelectionButton.apply(style: .secondaryTransparentIcon)

        let image = UIImage(named: "arrow_small_down_20")
        fieldSelectionButton.setImage(image?.tinted(with: .themeGray), for: .normal)
        fieldSelectionButton.setImage(image?.tinted(with: .themeGray50), for: .highlighted)

        fieldSelectionButton.addTarget(self, action: #selector(tapSortField), for: .touchUpInside)

        contentView.addSubview(marketFieldModeView)
        marketFieldModeView.snp.makeConstraints { maker in
            maker.leading.greaterThanOrEqualTo(fieldSelectionButton.snp.trailing).offset(CGFloat.margin8)
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.bottom.equalToSuperview().inset(10)
        }

        marketFieldModeView.onSelect = { [weak self] field in
            self?.onSelect?(field)
        }

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func tapSortField() {
        onTapSortField?()
    }

}

extension MarketListHeaderView {

    public func setSortingField(title: String) {
        fieldSelectionButton.setTitle(title, for: .normal)
    }

    public func setMarketField(field: MarketModule.MarketField) {
        marketFieldModeView.setSelected(field: field)
    }

}
