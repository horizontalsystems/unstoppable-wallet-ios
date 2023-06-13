import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class TextDropDownAndSettingsHeaderView: UITableViewHeaderFooterView {
    static let height: CGFloat = TextDropDownAndSettingsView.height

    private let view = TextDropDownAndSettingsView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    init() {
        super.init(reuseIdentifier: nil)
        commonInit()
    }

    private func commonInit() {
        contentView.addSubview(view)
        view.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var onTapDropDown: (() -> ())? {
        get { view.onTapDropDown }
        set { view.onTapDropDown = newValue }
    }

    var onTapSettings: (() -> ())? {
        get { view.onTapSettings }
        set { view.onTapSettings = newValue }
    }

    var onTapSelector: ((Int) -> ())? {
        get { view.onTapSelector }
        set { view.onTapSelector = newValue }
    }

    func bind(dropdownTitle: String?, settingsHidden: Bool = false) {
        view.set(dropdownTitle: dropdownTitle)
        view.set(settingsHidden: settingsHidden)
    }

    func setSelector(items: [String]) {
        view.setSelector(items: items)
    }

    func setSelector(index: Int) {
        view.setSelector(index: index)
    }

    func setSelector(isEnabled: Bool) {
        view.setSelector(isEnabled: isEnabled)
    }

}
