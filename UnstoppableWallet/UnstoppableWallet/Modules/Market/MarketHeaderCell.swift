import UIKit

class MarketHeaderCell: UITableViewCell {
    static let height: CGFloat = 108

    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let rightImageView = UIImageView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(CGFloat.margin16)
            make.top.equalToSuperview().inset(CGFloat.margin12)
        }

        titleLabel.font = .headline1
        titleLabel.textColor = .themeLeah

        contentView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin8)
        }

        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = .subhead2
        descriptionLabel.textColor = .themeGray

        contentView.addSubview(rightImageView)
        rightImageView.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin16)
            make.top.trailing.bottom.equalToSuperview()
            make.width.equalTo(76)
        }
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(title: String, description: String?, imageMode: ImageMode) {
        titleLabel.text = title
        descriptionLabel.text = description

        switch imageMode {
        case let .local(image):
            rightImageView.image = image
        case let .remote(imageUrl):
            rightImageView.setImage(withUrlString: imageUrl, placeholder: nil)
        }
    }
}

extension MarketHeaderCell {
    enum ImageMode {
        case local(image: UIImage?)
        case remote(imageUrl: String)
    }
}
