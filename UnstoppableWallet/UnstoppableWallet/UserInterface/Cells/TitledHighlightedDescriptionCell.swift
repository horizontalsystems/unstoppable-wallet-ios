import UIKit
import ThemeKit
import ComponentKit
import SectionsTableView

class TitledHighlightedDescriptionCell: BaseThemeCell {
    private static let horizontalMargin: CGFloat = .margin16

    private let descriptionView = TitledHighlightedDescriptionView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(Self.horizontalMargin)
            maker.top.equalToSuperview()
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

    var contentBackgroundColor: UIColor? {
        get { descriptionView.backgroundColor }
        set { descriptionView.backgroundColor = newValue }
    }

    var contentBorderColor: UIColor? {
        get { descriptionView.borderColor }
        set { descriptionView.borderColor = newValue }
    }

    var titleColor: UIColor? {
        get { descriptionView.titleColor }
        set { descriptionView.titleColor = newValue }
    }

    func bind(caution: TitledCaution) {
        titleIcon = UIImage(named: "warning_2_20")?.withRenderingMode(.alwaysTemplate)
        tintColor = caution.type == .error ? .themeLucian : .themeJacob
        titleText = caution.title
        titleColor = caution.type == .error ? .themeLucian : .themeJacob
        descriptionText = caution.text
        contentBackgroundColor = caution.type == .error ? UIColor(hex: 0xff4820, alpha: 0.2) : .themeYellow20
        contentBorderColor = caution.type == .error ? .themeLucian : .themeJacob
    }

    func cellHeight(containerWidth: CGFloat) -> CGFloat {
        isVisible ? Self.height(containerWidth: containerWidth, text: descriptionText ?? "") : 0
    }

}

extension TitledHighlightedDescriptionCell {

    static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let descriptionViewWidth = containerWidth - 2 * horizontalMargin
        let descriptionViewHeight = TitledHighlightedDescriptionView.height(containerWidth: descriptionViewWidth, text: text)
        return descriptionViewHeight
    }

}
