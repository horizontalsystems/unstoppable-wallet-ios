import UIKit
import UIExtensions
import ThemeKit
import SnapKit

class MarketListHeaderView: UITableViewHeaderFooterView {
    static let height: CGFloat = .heightSingleLineCell

    private let fieldSelectionButton = SelectionButton()
    private let marketFieldModeView = MarketFieldModeView()

    var onTapSortField: (() -> ())?
    var onSelect: ((MarketModule.MarketField) -> ())?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        backgroundView = UIView()
        backgroundView?.backgroundColor = .themeNavigationBarBackground

        let separatorView = UIView()
        separatorView.backgroundColor = .themeSteel20
        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        contentView.addSubview(fieldSelectionButton)
        fieldSelectionButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin8)
            maker.top.bottom.equalToSuperview()
        }

        fieldSelectionButton.setTitle(color: .themeGray)
        fieldSelectionButton.action = { [weak self] in self?.onTapSortField?() }
        fieldSelectionButton.setContentHuggingPriority(.required, for: .horizontal)

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

}

extension MarketListHeaderView {
    
    public func setSortingField(title: String) {
        fieldSelectionButton.set(title: title)
    }

    public func setMarketField(field: MarketModule.MarketField) {
        marketFieldModeView.setSelected(field: field)
    }

}
