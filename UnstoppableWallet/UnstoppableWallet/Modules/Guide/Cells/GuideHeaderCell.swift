import UIKit
import SnapKit
import ThemeKit
import AlamofireImage

class GuideHeaderCell: UITableViewCell {
    private static let imageHeight: CGFloat = 320
    private static let labelFont: UIFont = .title2
    private static let labelTopMargin: CGFloat = .margin6x
    private static let bottomPadding: CGFloat = .margin6x

    private let guideImageView = UIImageView()
    private let label = UILabel()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(guideImageView)
        guideImageView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(GuideHeaderCell.imageHeight)
        }

        guideImageView.contentMode = .scaleAspectFill
        guideImageView.clipsToBounds = true

        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.top.equalTo(guideImageView.snp.bottom).offset(GuideHeaderCell.labelTopMargin)
        }

        label.numberOfLines = 0
        label.font = GuideHeaderCell.labelFont
        label.textColor = .themeOz
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(imageUrl: String?, text: String?) {
        if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
            guideImageView.af.setImage(withURL: url)
        } else {
            guideImageView.image = nil
        }

        label.text = text
    }

}

extension GuideHeaderCell {

    static func height(containerWidth: CGFloat, text: String?) -> CGFloat {
        let textHeight = text?.height(forContainerWidth: containerWidth, font: labelFont) ?? 0
        return imageHeight + labelTopMargin + textHeight + bottomPadding
    }

}
