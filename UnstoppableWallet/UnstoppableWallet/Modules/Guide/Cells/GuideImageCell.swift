import UIKit
import SnapKit
import ThemeKit
import AlamofireImage

class GuideImageCell: UITableViewCell {
    private static let verticalPadding: CGFloat = .margin3x

    private let guideImageView = UIImageView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(guideImageView)
        guideImageView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.bottom.equalToSuperview().inset(GuideImageCell.verticalPadding)
        }

        guideImageView.contentMode = .scaleAspectFill
        guideImageView.clipsToBounds = true
        guideImageView.backgroundColor = .themeSteel20
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(imageUrl: URL, type: GuideImageType) {
        guideImageView.image = nil
        guideImageView.af.setImage(withURL: imageUrl)
    }

}

extension GuideImageCell {

    static func height(containerWidth: CGFloat, type: GuideImageType) -> CGFloat {
        let imageHeight: CGFloat

        switch type {
        case .landscape: imageHeight = containerWidth / 4 * 3
        case .portrait: imageHeight = containerWidth / 9 * 16
        case .square: imageHeight = containerWidth
        }

        return imageHeight + 2 * verticalPadding
    }

}
