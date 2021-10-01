import UIKit

class MarketDiscoveryCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let nameLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .themeLawrence
        contentView.cornerRadius = .cornerRadius12

        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.top.trailing.equalToSuperview()
        }

        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview().inset(CGFloat.margin12)
        }

        nameLabel.numberOfLines = 0
        nameLabel.font = .subhead1
        nameLabel.textColor = .themeOz
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(viewItem: MarketDiscoveryViewModel.DiscoveryViewItem) {
        switch viewItem.imageType {
        case .local(let name):
            imageView.image = UIImage(named: name)
        case .remote(let url):
            imageView.setImage(withUrlString: url, placeholder: nil)
        }

        nameLabel.text = viewItem.name
    }

}
