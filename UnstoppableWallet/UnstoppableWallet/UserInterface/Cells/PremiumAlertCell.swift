import Kingfisher
import SnapKit
import UIKit

class PremiumAlertCell: UITableViewCell {
    private static let padding: CGFloat = .margin16

    private let containerView = UIView()
    private let stackView = UIStackView()
    private let titleIcon = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(containerView)
        containerView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(Self.padding)
        }

        containerView.borderWidth = .heightOneDp
        containerView.cornerRadius = .cornerRadius16
        containerView.borderColor = .themeJacob
        containerView.cornerCurve = .continuous

        containerView.addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.bottom.equalToSuperview().inset(CGFloat.margin16)
        }

        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = .margin8

        let titleContainerView = UIView()
        titleContainerView.addSubview(titleIcon)

        titleIcon.snp.makeConstraints { maker in
            maker.centerY.leading.equalToSuperview()
            maker.size.equalTo(CGFloat.iconSize20)
        }

        titleContainerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.top.bottom.trailing.equalToSuperview()
            maker.leading.equalTo(titleIcon.snp.trailing).offset(6)
        }

        titleLabel.font = .headline2
        titleLabel.textColor = .themeJacob

        stackView.addArrangedSubview(titleContainerView)

        stackView.addArrangedSubview(subtitleLabel)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.font = .subhead2
        subtitleLabel.textColor = .themeLeah
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func setTitle(title: String?, color: UIColor) {
        titleLabel.text = title
        titleLabel.textColor = color
    }

    var subtitle: String? {
        get { subtitleLabel.text }
        set {
            subtitleLabel.text = newValue
            subtitleLabel.isHidden = newValue == nil
        }
    }

    func setIcon(name: String, color: UIColor) {
        titleIcon.image = UIImage(named: name)?
            .withRenderingMode(.alwaysTemplate)

        titleIcon.tintColor = color
    }

    func setBorder(color: UIColor) {
        containerView.borderColor = color
    }
}

extension PremiumAlertCell {
    static func height(title: String, subtitle: String?, width: CGFloat) -> CGFloat {
        padding * 2 + CGFloat.margin16 * 2 +
            TextComponent.height(width: .greatestFiniteMagnitude, font: .headline1, text: title) +
            (subtitle.map { TextComponent.height(width: width - 2 * 40, font: .subhead2, text: $0) + 8 } ?? 0)
    }
}
