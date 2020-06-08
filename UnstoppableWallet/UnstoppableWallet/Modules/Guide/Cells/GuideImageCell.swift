import UIKit
import SnapKit
import ThemeKit
import AlamofireImage

class GuideImageCell: UITableViewCell {
    private static let imageHeight: CGFloat = 320
    private static let verticalPadding: CGFloat = .margin3x

    private let guideImageView = UIImageView()

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
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(imageUrl: String) {
        guideImageView.image = nil

        if let url = URL(string: imageUrl) {
            guideImageView.af.setImage(withURL: url)
        }
    }

}

extension GuideImageCell {

    static func height(containerWidth: CGFloat) -> CGFloat {
        imageHeight + 2 * verticalPadding
    }

}
