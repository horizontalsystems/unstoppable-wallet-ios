import UIKit
import UIExtensions
import ThemeKit
import SnapKit

class MarketListHeaderView: UITableViewHeaderFooterView {
    private let fieldSelectionButton = SelectionButton()
    private let periodSelectionButton = SelectionButton()

    private var onTapSortField: (() -> ())?
    private var onTapPeriod: (() -> ())?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        backgroundView = UIView()
        backgroundView?.backgroundColor = .themeNavigationBarBackground

        contentView.addSubview(fieldSelectionButton)
        fieldSelectionButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.top.bottom.equalToSuperview()
        }

        fieldSelectionButton.setTitle(color: .themeGray)
        fieldSelectionButton.action = { [weak self] in self?.onTapSortField?() }

        contentView.addSubview(periodSelectionButton)
        periodSelectionButton.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview()
            maker.top.bottom.equalToSuperview()
        }

        periodSelectionButton.setTitle(color: .themeGray)
        periodSelectionButton.action = { [weak self] in self?.onTapPeriod?() }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(sortingField: String?) {
        fieldSelectionButton.set(title: sortingField)
    }

    func set(period: String?) {
        periodSelectionButton.set(title: period)
    }

    func set(sortingFieldAction: (() -> ())?) {
        onTapSortField = sortingFieldAction
    }

    func set(periodAction: (() -> ())?) {
        onTapPeriod = periodAction
    }

}
