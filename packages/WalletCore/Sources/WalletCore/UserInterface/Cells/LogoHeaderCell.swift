import Kingfisher
import SnapKit
import UIKit

class LogoHeaderCell: UITableViewCell {
    private static let logoSize: CGFloat = 48
    private static let verticalMargin: CGFloat = .margin24

    private let logoImageView = UIImageView()

    private let stackView = UIStackView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(logoImageView)
        logoImageView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(Self.verticalMargin)
            maker.centerX.equalToSuperview()
            maker.size.equalTo(Self.logoSize)
        }

        logoImageView.contentMode = .scaleAspectFit
        logoImageView.cornerRadius = .cornerRadius8
        logoImageView.layer.cornerCurve = .continuous
        logoImageView.clipsToBounds = true
        logoImageView.backgroundColor = .clear

        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin32)
            maker.trailing.equalToSuperview().inset(CGFloat.margin32)
            maker.top.equalTo(logoImageView.snp.bottom).offset(Self.verticalMargin)
            maker.bottom.equalToSuperview().inset(Self.verticalMargin)
        }

        stackView.axis = .vertical
        stackView.spacing = 1

        stackView.addArrangedSubview(titleLabel)

        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        titleLabel.font = .headline1
        titleLabel.textColor = .themeLeah

        stackView.addArrangedSubview(subtitleLabel)

        subtitleLabel.isHidden = true
        subtitleLabel.textAlignment = .center
        subtitleLabel.font = .subhead1
        subtitleLabel.textColor = .themeGray
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    var image: UIImage? {
        get { logoImageView.image }
        set { logoImageView.image = newValue }
    }

    var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }

    var subtitle: String? {
        get { subtitleLabel.text }
        set {
            subtitleLabel.text = newValue
            subtitleLabel.isHidden = newValue == nil
        }
    }

    func set(imageUrl: String?) {
        logoImageView.kf.setImage(with: imageUrl.flatMap { URL(string: $0) }, placeholder: UIImage(named: "placeholder_rectangle_32"))
    }
}

extension LogoHeaderCell {
    static func height(title: String, url: String?, width: CGFloat) -> CGFloat {
        logoSize + verticalMargin * 2 +
            TextComponent.height(width: width - 2 * .margin32, font: .headline1, text: title) +
            (url.map { TextComponent.height(width: width - 2 * .margin32, font: .subhead1, text: $0) + 1 } ?? 0) + verticalMargin
    }
}
