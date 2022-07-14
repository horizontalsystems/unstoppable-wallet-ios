import UIKit

class MarketTopHeaderCell: UITableViewCell {
    static let height: CGFloat = 108

    private let nameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let topImageView = UIImageView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalToSuperview().offset(CGFloat.margin12)
        }

        nameLabel.font = .headline1
        nameLabel.textColor = .themeLeah
        nameLabel.text = "market.top.title".localized

        contentView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(nameLabel.snp.bottom).offset(CGFloat.margin8)
        }

        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = .subhead2
        descriptionLabel.textColor = .themeGray
        descriptionLabel.text = "market.top.description".localized

        contentView.addSubview(topImageView)
        topImageView.snp.makeConstraints { maker in
            maker.leading.equalTo(descriptionLabel.snp.trailing).offset(CGFloat.margin16)
            maker.top.trailing.equalToSuperview()
            maker.width.equalTo(76)
        }

        topImageView.image = UIImage(named: "Categories - Top Coins")
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(title: String, description: String, imageName: String) {
        nameLabel.text = title
        descriptionLabel.text = description
        topImageView.image = UIImage(named: imageName)
    }

}
