import UIKit
import SnapKit

class DescriptionCollectionHeader: UICollectionReusableView {
    var label: UILabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = RestoreTheme.descriptionFont
        label.numberOfLines = 0
        label.textColor = RestoreTheme.descriptionTextColor

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview()
            maker.top.equalToSuperview().offset(RestoreTheme.descriptionTopMargin)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(text: String) {
        label.text = text
    }

    static func height(forContainerWidth containerWidth: CGFloat, text: String) -> CGFloat {
        return ceil(text.height(forContainerWidth: containerWidth, font: RestoreTheme.descriptionFont) + RestoreTheme.descriptionTopMargin + RestoreTheme.descriptionBottomMargin)
    }

}
