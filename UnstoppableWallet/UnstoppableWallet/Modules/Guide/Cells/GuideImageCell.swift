import UIKit
import SnapKit
import ThemeKit
import AlamofireImage

class GuideImageCell: UITableViewCell {
    private static let imageHeight: CGFloat = 320
    private static let verticalPadding: CGFloat = .margin3x
    private static let horizontalPadding: CGFloat = .margin6x
    private static let labelTopMargin: CGFloat = .margin6x
    private static let labelFont: UIFont = .subhead2

    private let guideImageView = UIImageView()
    private let label = UILabel()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(guideImageView)
        guideImageView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalToSuperview().inset(GuideImageCell.verticalPadding)
            maker.height.equalTo(GuideImageCell.imageHeight)
        }

        guideImageView.contentMode = .scaleAspectFill
        guideImageView.clipsToBounds = true

        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(GuideImageCell.horizontalPadding)
            maker.top.equalTo(guideImageView.snp.bottom).offset(GuideImageCell.labelTopMargin)
            maker.bottom.equalToSuperview().inset(GuideImageCell.verticalPadding)
        }

        label.numberOfLines = 0
        label.font = GuideImageCell.labelFont
        label.textColor = .themeGray
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(imageUrl: String, altText: String?) {
        if let url = URL(string: imageUrl) {
            guideImageView.af.setImage(withURL: url)
        } else {
            guideImageView.image = nil
        }

        label.text = altText
    }

}

extension GuideImageCell {

    static func height(containerWidth: CGFloat, altText: String?) -> CGFloat {
        var altTextHeight: CGFloat = 0

        if let altText = altText {
            let textWidth = containerWidth - 2 * horizontalPadding
            let textHeight = altText.height(forContainerWidth: textWidth, font: labelFont)
            altTextHeight = textHeight + labelTopMargin
        }

        return imageHeight + altTextHeight + 2 * verticalPadding
    }

}
