import UIKit
import ThemeKit
import SnapKit
import AlamofireImage

class GuideCell: UICollectionViewCell {
    private let cardView = CardView(insets: .zero)

    private let titleLabel = UILabel()
    private let backgroundImageView = UIImageView()
    private let coinImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(cardView)
        cardView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        cardView.contentView.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        backgroundImageView.contentMode = .scaleAspectFill

        cardView.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview().inset(CGFloat.margin4x)
        }

        titleLabel.numberOfLines = 0
        titleLabel.font = .title3
        titleLabel.textColor = .themeOz

        cardView.contentView.addSubview(coinImageView)
        coinImageView.snp.makeConstraints { maker in
            maker.top.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(viewItem: GuideViewItem) {
        titleLabel.text = viewItem.title

        if let imageUrl = viewItem.imageUrl, let url = URL(string: imageUrl) {
            backgroundImageView.af.setImage(withURL: url)
        } else {
            backgroundImageView.image = nil
        }

        coinImageView.image = viewItem.coinCode.flatMap { UIImage(named: $0.lowercased())?.tinted(with: .themeJacob) }
    }

}
