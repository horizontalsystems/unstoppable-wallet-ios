import UIKit
import ThemeKit
import ComponentKit
import SectionsTableView
import SnapKit

class NonStandardPhraseCell: BaseThemeCell {
    private static let horizontalMargin: CGFloat = .margin16

    private let descriptionView = NonStandardPhraseView()
    var topOffset: CGFloat = 0 {
        didSet {
            descriptionView.snp.updateConstraints { maker in
                maker.top.equalToSuperview().offset(topOffset)
            }
            contentView.setNeedsUpdateConstraints()
        }
    }

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(Self.horizontalMargin)
            maker.top.equalToSuperview().offset(topOffset)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func cellHeight(containerWidth: CGFloat) -> CGFloat {
        isVisible ? Self.height(containerWidth: containerWidth) : 0
    }

}

extension NonStandardPhraseCell {

    static func height(containerWidth: CGFloat) -> CGFloat {
        let descriptionViewWidth = containerWidth - 2 * horizontalMargin
        let descriptionViewHeight = NonStandardPhraseView.height(containerWidth: descriptionViewWidth, text: NonStandardPhraseView.fullText)
        return descriptionViewHeight
    }

}
