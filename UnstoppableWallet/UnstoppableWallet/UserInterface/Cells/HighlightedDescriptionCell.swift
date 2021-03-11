import UIKit

class HighlightedDescriptionCell: UITableViewCell {
    private static let horizontalMargin: CGFloat = .margin4x
    private static let verticalMargin: CGFloat = .margin3x

    private let descriptionView = HighlightedDescriptionView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(HighlightedDescriptionCell.horizontalMargin)
            maker.top.equalToSuperview().offset(HighlightedDescriptionCell.verticalMargin)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var descriptionText: String? {
        get { descriptionView.text }
        set { descriptionView.text = newValue }
    }

}

extension HighlightedDescriptionCell {

    static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let descriptionViewWidth = containerWidth - 2 * horizontalMargin
        let descriptionViewHeight = HighlightedDescriptionView.height(containerWidth: descriptionViewWidth, text: text)
        return descriptionViewHeight + 2 * verticalMargin
    }

}
