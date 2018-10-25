import UIKit
import SnapKit

class DescriptionCollectionHeader: UICollectionReusableView {

    var label: UILabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = RestoreTheme.descriptionFont
        label.numberOfLines = 0
        label.textColor = RestoreTheme.descriptionTextColor
        label.textAlignment = .center

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(RestoreTheme.descriptionHorizontalMargin)
            maker.trailing.equalToSuperview().offset(-RestoreTheme.descriptionHorizontalMargin)
            maker.top.equalToSuperview().offset(RestoreTheme.descriptionVerticalMargin)
            maker.bottom.equalToSuperview().offset(-RestoreTheme.descriptionVerticalMargin)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(text: String) {
        label.text = text
    }

    static func height(forContainerWidth containerWidth: CGFloat, text: String) -> CGFloat {
        return ceil(text.height(forContainerWidth: containerWidth - 2 * RestoreTheme.descriptionHorizontalMargin, font: RestoreTheme.descriptionFont) + 2 * RestoreTheme.descriptionVerticalMargin)
    }

}
