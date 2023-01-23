import UIKit
import SnapKit
import ComponentKit

class FilterHeaderView: UITableViewHeaderFooterView {
    static var height: CGFloat = FilterView.height

    private let view: FilterView

    init(buttonStyle: SecondaryButton.Style) {
        view = FilterView(buttonStyle: buttonStyle)

        super.init(reuseIdentifier: nil)

        contentView.addSubview(view)
        view.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        backgroundView = UIView()
        backgroundView?.backgroundColor = .themeNavigationBarBackground
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    var autoDeselect: Bool {
        get { view.autoDeselect }
        set { view.autoDeselect = newValue }
    }

    var onSelect: ((Int) -> ())? {
        get { view.onSelect }
        set { view.onSelect = newValue }
    }

    var headerHeight: CGFloat {
        view.headerHeight
    }

    func reload(filters: [FilterView.ViewItem]) {
        view.reload(filters: filters)
    }

    func select(index: Int) {
        view.select(index: index)
    }

}
