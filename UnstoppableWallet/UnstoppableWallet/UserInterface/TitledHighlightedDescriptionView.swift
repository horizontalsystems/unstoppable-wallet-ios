import UIKit
import SnapKit

class TitledHighlightedDescriptionView: HighlightedDescriptionBaseView {
    private let titleIconImageView = UIImageView()
    private let titleLabel = UILabel()

    override public init() {
        super.init()

        addSubview(titleIconImageView)
        titleIconImageView.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview().inset(HighlightedDescriptionBaseView.verticalPadding)
        }

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(titleIconImageView.snp.trailing).offset(HighlightedDescriptionBaseView.verticalPadding)
            maker.centerY.equalTo(titleIconImageView)
        }

        titleLabel.font = .subhead1
        titleLabel.textColor = .themeYellowD

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(HighlightedDescriptionBaseView.sidePadding)
            maker.top.equalTo(titleIconImageView.snp.bottom).offset(HighlightedDescriptionBaseView.verticalPadding)
            maker.bottom.equalToSuperview().inset(HighlightedDescriptionBaseView.verticalPadding)
        }

        label.numberOfLines = 0
        label.font = HighlightedDescriptionBaseView.font
        label.textColor = .themeLeah
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var titleIcon: UIImage? {
        get { titleIconImageView.image }
        set { titleIconImageView.image = newValue }
    }

    var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }

    var titleColor: UIColor? {
        get { titleLabel.textColor }
        set { titleLabel.textColor = newValue }
    }

}

extension TitledHighlightedDescriptionView {

    public static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let textHeight = text.height(forContainerWidth: containerWidth - 2 * sidePadding, font: font)
        return verticalPadding + 20 + textHeight + 2 * verticalPadding
    }

}
