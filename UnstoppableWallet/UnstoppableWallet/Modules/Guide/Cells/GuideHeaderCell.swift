import UIKit
import SnapKit
import ThemeKit
import AlamofireImage

class GuideHeaderCell: UITableViewCell {
    static let height: CGFloat = 320

    private let guideImageView = UIImageView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(guideImageView)
        guideImageView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        guideImageView.contentMode = .scaleAspectFill
        guideImageView.clipsToBounds = true
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(imageUrl: String?) {
        if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
            guideImageView.af.setImage(withURL: url)
        } else {
            guideImageView.image = nil
        }
    }

}
