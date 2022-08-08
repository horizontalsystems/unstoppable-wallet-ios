import UIKit

class MarketCategoryHeaderCell: UITableViewCell {
    static let height: CGFloat = 108

    private let nameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let categoryImageView = UIImageView()

    private let topPlatformImageHolder = UIView()
    private let topPlatformImageView = UIImageView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        let stackView = UIStackView()
        stackView.spacing = .margin16

        let textContainer = UIView()
        textContainer.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalToSuperview().offset(CGFloat.margin12)
        }

        nameLabel.font = .headline1
        nameLabel.textColor = .themeLeah

        textContainer.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(nameLabel.snp.bottom).offset(CGFloat.margin8)
        }

        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = .subhead2
        descriptionLabel.textColor = .themeGray

        stackView.addArrangedSubview(textContainer)

        stackView.addArrangedSubview(categoryImageView)
        categoryImageView.snp.makeConstraints { maker in
            maker.width.equalTo(76)
        }

        let backgroundView = UIView()
        topPlatformImageHolder.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { maker in
            maker.size.equalTo(CGFloat.iconSize48)
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
        }

        backgroundView.backgroundColor = .themeLawrence
        backgroundView.cornerRadius = .cornerRadius12
        backgroundView.layer.cornerCurve = .continuous

        backgroundView.addSubview(topPlatformImageView)
        topPlatformImageView.snp.makeConstraints { maker in
            maker.size.equalTo(CGFloat.iconSize24)
            maker.center.equalToSuperview()
        }

        stackView.addArrangedSubview(topPlatformImageHolder)

        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.trailing.top.bottom.equalToSuperview()
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(viewItem: MarketCategoryViewModel.ViewItem) {
        switch viewItem.imageMode {
        case .large:
            categoryImageView.setImage(withUrlString: viewItem.imageUrl, placeholder: nil)
            topPlatformImageHolder.isHidden = true
        case .small:
            topPlatformImageView.setImage(withUrlString: viewItem.imageUrl, placeholder: nil)
            categoryImageView.isHidden = true
        }

        nameLabel.text = viewItem.name
        descriptionLabel.text = viewItem.description
    }

}
