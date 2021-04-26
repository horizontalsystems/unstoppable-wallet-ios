import UIKit
import UIExtensions
import ThemeKit
import SnapKit
import ComponentKit

class MarketListHeaderView: UITableViewHeaderFooterView {
    static let height: CGFloat = .heightSingleLineCell

    private let fieldSelectionButton = ThemeButton()
    private let marketFieldModeView = SingleSelectorView()

    private var marketFields = [MarketModule.MarketField]()

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
        fieldSelectionButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        fieldSelectionButton.setImageTintColor(.themeGray, for: .normal)
        fieldSelectionButton.setImageTintColor(.themeGray50, for: .highlighted)

        fieldSelectionButton.addTarget(self, action: #selector(tapSortField), for: .touchUpInside)

        contentView.addSubview(marketFieldModeView)
        marketFieldModeView.snp.makeConstraints { maker in
            maker.leading.equalTo(fieldSelectionButton.snp.trailing).priority(.high)
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalToSuperview().inset(10)
            maker.height.equalTo(24)
        }

        marketFieldModeView.onSelect = { [weak self] index in
            if let marketFields = self?.marketFields, marketFields.count > index {
                self?.onSelect?(marketFields[index])
            }
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

    public func setSortingField(image: UIImage?) {
        fieldSelectionButton.setImage(image, for: .normal)
    }

    public func set(marketFields: [MarketModule.MarketField]) {
        self.marketFields = marketFields
        marketFieldModeView.set(items: marketFields.map { $0.title })
    }

    public func setMarket(field: MarketModule.MarketField) {
        if let index = marketFields.firstIndex(of: field) {
            marketFieldModeView.setSelected(index: index)
        }
    }

}
