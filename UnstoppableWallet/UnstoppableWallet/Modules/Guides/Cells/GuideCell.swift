import UIKit
import ThemeKit
import SnapKit
import AlamofireImage

class GuideCell: UICollectionViewCell {
    private let cardView = CardView(insets: .zero)

    private let guideImageView = UIImageView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(cardView)
        cardView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        cardView.contentView.addSubview(guideImageView)
        guideImageView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(160)
        }

        guideImageView.contentMode = .scaleAspectFill
        guideImageView.clipsToBounds = true

        cardView.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(guideImageView.snp.bottom).offset(CGFloat.margin4x)
        }

        titleLabel.numberOfLines = 0
        titleLabel.font = .title3
        titleLabel.textColor = .themeOz
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(viewItem: GuideViewItem) {
        titleLabel.text = viewItem.title

        if let imageUrl = viewItem.imageUrl, let url = URL(string: imageUrl) {
            guideImageView.af.setImage(withURL: url)
        } else {
            guideImageView.image = nil
        }
    }

}
