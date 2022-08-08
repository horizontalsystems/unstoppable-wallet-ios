import UIKit

class MarketDiscoveryCell: UICollectionViewCell {
    static let cellHeight: CGFloat = 140

    private let imageView = UIImageView()
    private let nameLabel = UILabel()
    private let stackView = UIStackView()
    private let marketCapLabel = UILabel()
    private let diffLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .themeLawrence
        contentView.cornerRadius = .cornerRadius12
        contentView.layer.cornerCurve = .continuous

        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.top.trailing.equalToSuperview()
        }

        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.leading.bottom.equalToSuperview().inset(CGFloat.margin12)
        }

        stackView.axis = .horizontal
        stackView.spacing = .margin6

        stackView.addArrangedSubview(marketCapLabel)
        marketCapLabel.font = .caption
        marketCapLabel.textColor = .themeGray

        stackView.addArrangedSubview(diffLabel)
        diffLabel.font = .caption

        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin12)
            maker.bottom.equalTo(stackView.snp.top).offset(-CGFloat.margin8)
        }

        nameLabel.numberOfLines = 0
        nameLabel.font = .subhead1
        nameLabel.textColor = .themeLeah
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

        marketCapLabel.text = viewItem.marketCap
        diffLabel.text = viewItem.diff
        diffLabel.textColor = viewItem.diffType.textColor

        nameLabel.snp.updateConstraints { maker in
            maker.bottom.equalTo(stackView.snp.top).offset(viewItem.marketCap == nil ? 0 : -CGFloat.margin8)
        }
    }

    func set(viewItem: MarketOverviewCategoryViewModel.ViewItem) {
        imageView.setImage(withUrlString: viewItem.imageUrl, placeholder: nil)

        nameLabel.text = viewItem.name

        marketCapLabel.text = viewItem.marketCap
        diffLabel.text = viewItem.diff
        diffLabel.textColor = viewItem.diffType.textColor

        nameLabel.snp.updateConstraints { maker in
            maker.bottom.equalTo(stackView.snp.top).offset(viewItem.marketCap == nil ? 0 : -CGFloat.margin8)
        }
    }

}
