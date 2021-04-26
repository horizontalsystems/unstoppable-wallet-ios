import UIKit
import ThemeKit
import ComponentKit

class TitledHighlightedDescriptionCell: BaseThemeCell {
    private static let horizontalMargin: CGFloat = .margin16
    private static let verticalMargin: CGFloat = .margin12

    private let descriptionView = TitledHighlightedDescriptionView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(TitledHighlightedDescriptionCell.horizontalMargin)
            maker.top.equalToSuperview().offset(TitledHighlightedDescriptionCell.verticalMargin)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var titleIcon: UIImage? {
        get { descriptionView.titleIcon }
        set { descriptionView.titleIcon = newValue }
    }

    var titleText: String? {
        get { descriptionView.title }
        set { descriptionView.title = newValue }
    }

    var descriptionText: String? {
        get { descriptionView.text }
        set { descriptionView.text = newValue }
    }

}

extension TitledHighlightedDescriptionCell {

    static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let descriptionViewWidth = containerWidth - 2 * horizontalMargin
        let descriptionViewHeight = TitledHighlightedDescriptionView.height(containerWidth: descriptionViewWidth, text: text)
        return descriptionViewHeight + 2 * verticalMargin
    }

}
