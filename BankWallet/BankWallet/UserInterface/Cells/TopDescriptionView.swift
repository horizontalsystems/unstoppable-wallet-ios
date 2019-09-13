import UIKit
import SnapKit

class TopDescriptionView: UITableViewHeaderFooterView {
    private let label = UILabel()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        label.numberOfLines = 0
        label.font = AppTheme.topDescriptionFont
        label.textColor = AppTheme.topDescriptionColor
        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(AppTheme.topDescriptionMargin)
            maker.top.equalToSuperview().offset(AppTheme.topDescriptionSmallMargin)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(text: String?) {
        label.text = text
    }

}

extension TopDescriptionView {

    static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let textHeight = ceil(text.height(forContainerWidth: containerWidth - 2 * AppTheme.topDescriptionMargin, font: AppTheme.topDescriptionFont))
        return textHeight + AppTheme.topDescriptionMargin + AppTheme.topDescriptionSmallMargin
    }

}
