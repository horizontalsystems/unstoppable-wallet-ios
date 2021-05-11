import UIKit
import SnapKit

class CoinCategoryHeaderCell: UITableViewCell {
    private let label = UILabel()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.bottom.equalToSuperview().inset(CGFloat.margin12)
        }

        selectionStyle = .none
        backgroundColor = .clear

        label.font = .headline2
        label.textColor = .themeBran
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var title: String? {
        get { label.text }
        set { label.text = newValue }
    }

    public var titleColor: UIColor {
        get { label.textColor }
        set { label.textColor = newValue }
    }

    public var titleFont: UIFont {
        get { label.font }
        set { label.font = newValue }
    }

}
