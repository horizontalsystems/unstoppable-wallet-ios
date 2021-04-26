import UIKit
import SnapKit
import ThemeKit
import ComponentKit

open class ItemSelectorSimpleCell: BaseSelectableThemeCell {
    private let titleLabel = UILabel()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        wrapperView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.bottom.equalToSuperview()
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }

    public var titleColor: UIColor {
        get { titleLabel.textColor }
        set { titleLabel.textColor = newValue }
    }

}
