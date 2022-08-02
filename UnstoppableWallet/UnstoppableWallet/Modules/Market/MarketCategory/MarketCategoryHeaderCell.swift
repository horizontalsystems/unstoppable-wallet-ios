import UIKit

class MarketCategoryHeaderCell: UITableViewCell {
    static let height: CGFloat = 108

    private let nameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let categoryImageView = UIImageView()

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

        contentView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(nameLabel.snp.bottom).offset(CGFloat.margin8)
        }

        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = .subhead2
        descriptionLabel.textColor = .themeGray

        contentView.addSubview(categoryImageView)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(viewItem: MarketCategoryViewModel.ViewItem) {
        categoryImageView.snp.remakeConstraints { maker in
            maker.leading.equalTo(descriptionLabel.snp.trailing).offset(CGFloat.margin16)

            switch viewItem.imageMode {
            case .large:
                maker.top.trailing.equalToSuperview()
                maker.width.equalTo(76)
            case .small:
                maker.centerY.equalToSuperview()
                maker.size.equalTo(CGFloat.iconSize48)
                maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            }
        }

        nameLabel.text = viewItem.name
        descriptionLabel.text = viewItem.description
        categoryImageView.setImage(withUrlString: viewItem.imageUrl, placeholder: nil)
    }

}
