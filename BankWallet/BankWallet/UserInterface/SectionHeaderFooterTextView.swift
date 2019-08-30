import UIKit
import SnapKit

public class SectionHeaderFooterTextView: UITableViewHeaderFooterView {
    private let label = UILabel()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        contentView.addSubview(label)

        label.numberOfLines = 0
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(AppTheme.footerTextMargin)
            maker.top.bottom.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(title: String, font: UIFont = AppTheme.footerTextFont, color: UIColor = AppTheme.footerTextColor, topMargin: CGFloat, bottomMargin: CGFloat) {
        label.text = title
        label.font = font
        label.textColor = color

        label.snp.updateConstraints { maker in
            maker.top.equalToSuperview().offset(topMargin)
            maker.bottom.equalToSuperview().offset(-bottomMargin)
        }
        label.setNeedsUpdateConstraints()
    }

    static func textHeight(forContainerWidth containerWidth: CGFloat, text: String, font: UIFont = AppTheme.footerTextFont) -> CGFloat {
        return ceil(text.height(forContainerWidth: containerWidth - 2 * AppTheme.footerTextMargin, font: font))
    }

}
