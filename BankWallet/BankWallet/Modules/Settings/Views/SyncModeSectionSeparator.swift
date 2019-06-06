import UIKit
import UIExtensions
import SnapKit

class SyncModeSectionSeparator: SectionSeparator {

    let descriptionLabel = UILabel()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = SyncModeTheme.separatorDescriptionColor
        descriptionLabel.font = SyncModeTheme.separatorDescriptionFont
        contentView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SyncModeTheme.cellBigMargin)
            maker.top.equalToSuperview().offset(SyncModeTheme.cellMediumMargin)
            maker.trailing.equalToSuperview().offset(-SyncModeTheme.cellBigMargin)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(description: String, showTopSeparator: Bool = true, showBottomSeparator: Bool = true) {
        super.bind(showTopSeparator: showTopSeparator, showBottomSeparator: showBottomSeparator)

        descriptionLabel.text = description
    }

    class func height(for description: String, containerWidth: CGFloat) -> CGFloat {
        return ceil(description.height(forContainerWidth: containerWidth - 2 * SyncModeTheme.cellBigMargin, font: SyncModeTheme.separatorDescriptionFont) + SyncModeTheme.cellMediumMargin + SyncModeTheme.separatorBottomMargin)
    }

}
