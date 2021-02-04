import UIKit
import ThemeKit
import SnapKit

class CautionCell: UITableViewCell {
    private let cautionView = CautionView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(cautionView)
        cautionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin48)
            maker.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var spacing: CGFloat {
        get { cautionView.spacing }
        set { cautionView.spacing = newValue }
    }

    var cautionImage: UIImage? {
        get { cautionView.image }
        set { cautionView.image = newValue }
    }

    var cautionText: String? {
        get { cautionView.text }
        set { cautionView.text = newValue }
    }

    var cautionTextColor: UIColor {
        get { cautionView.textColor }
        set { cautionView.textColor = newValue }
    }

    var cautionFont: UIFont {
        get { cautionView.font }
        set { cautionView.font = newValue }
    }

}
