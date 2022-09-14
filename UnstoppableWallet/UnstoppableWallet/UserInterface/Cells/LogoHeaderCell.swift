import UIKit
import SnapKit
import ThemeKit

class LogoHeaderCell: UITableViewCell {
    private static let logoSize: CGFloat = 72
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
            maker.leading.equalToSuperview().inset(CGFloat.margin24)
            maker.size.equalTo(Self.logoSize)
        }

        logoImageView.contentMode = .scaleAspectFill
        logoImageView.cornerRadius = .cornerRadius16
        logoImageView.layer.cornerCurve = .continuous
        logoImageView.clipsToBounds = true
        logoImageView.backgroundColor = .themeSteel20

        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.leading.equalTo(logoImageView.snp.trailing).offset(CGFloat.margin16)
            maker.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.centerY.equalTo(logoImageView)
        }

        stackView.axis = .vertical
        stackView.spacing = .margin8

        stackView.addArrangedSubview(titleLabel)

        titleLabel.numberOfLines = 2
        titleLabel.font = .headline1
        titleLabel.textColor = .themeLeah

        stackView.addArrangedSubview(subtitleLabel)

        subtitleLabel.isHidden = true
        subtitleLabel.font = .subhead2
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

    func set(imageUrl: String?, placeholderImage: UIImage? = nil) {
        logoImageView.kf.setImage(with: imageUrl.flatMap { URL(string: $0) }, placeholder: placeholderImage)
    }

}

extension LogoHeaderCell {

    static var height: CGFloat {
        logoSize + verticalMargin * 2
    }

}
