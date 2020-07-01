import UIKit
import SnapKit
import ThemeKit
import AlamofireImage

class GuideImageCell: UITableViewCell {
    private static let verticalPadding: CGFloat = .margin3x

    private let guideImageView = UIImageView()
    private let placeholderImageView = UIImageView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(placeholderImageView)
        placeholderImageView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview() // constraints are remade in bind
        }

        placeholderImageView.image = UIImage(named: "Guide Image Placeholder")
        placeholderImageView.contentMode = .center
        placeholderImageView.backgroundColor = .themeSteel20

        contentView.addSubview(guideImageView)
        guideImageView.snp.makeConstraints { maker in
            maker.edges.equalTo(placeholderImageView)
        }

        guideImageView.contentMode = .scaleAspectFill
        guideImageView.clipsToBounds = true
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(imageUrl: URL, type: GuideImageType, tight: Bool) {
        guideImageView.image = nil
        guideImageView.af.setImage(withURL: imageUrl)

        placeholderImageView.snp.remakeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.bottom.equalToSuperview().inset(tight ? 0 : GuideImageCell.verticalPadding)
        }
    }

}

extension GuideImageCell {

    static func height(containerWidth: CGFloat, type: GuideImageType, tight: Bool) -> CGFloat {
        var imageHeight: CGFloat

        switch type {
        case .landscape: imageHeight = containerWidth / 4 * 3
        case .portrait: imageHeight = containerWidth / 9 * 16
        case .square: imageHeight = containerWidth
        }

        if !tight {
            imageHeight += 2 * verticalPadding
        }

        return imageHeight
    }

}
