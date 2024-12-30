import ComponentKit
import SnapKit
import ThemeKit
import UIKit

class MainSettingsPremiumCell: UITableViewCell {
    public static let height: CGFloat = 130

    private let cardView = CardView(insets: .zero)

    private let titleLabel = UILabel()
    private let titleDescription = UILabel()
    private let tryForFreeLabel = UILabel()
    private let boxImageView = UIImageView()

    private let radialBackgroundView = RadialBackgroundView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(cardView)
        contentView.clipsToBounds = true

        cardView.clipsToBounds = true
        cardView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.bottom.equalToSuperview()
        }

        cardView.contentView.addSubview(radialBackgroundView)
        radialBackgroundView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        cardView.contentView.addSubview(boxImageView)
        boxImageView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin6)
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.size.equalTo(118)
        }

        boxImageView.image = UIImage(named: "premium_box")

        cardView.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin16)
            maker.leading.equalToSuperview().offset(CGFloat.margin16)
        }

        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.font = .headline1
        titleLabel.textColor = .themeLeah
        titleLabel.text = "premium.cell.title".localized

        cardView.contentView.addSubview(tryForFreeLabel)
        tryForFreeLabel.snp.makeConstraints { maker in
            maker.bottom.equalToSuperview().inset(CGFloat.margin16)
            maker.leading.equalToSuperview().offset(CGFloat.margin16)
        }

        tryForFreeLabel.setContentHuggingPriority(.required, for: .horizontal)
        tryForFreeLabel.font = .subhead2
        tryForFreeLabel.textColor = .themeGreenD
        tryForFreeLabel.text = "premium.cell.try".localized

        cardView.contentView.addSubview(titleDescription)
        titleDescription.snp.makeConstraints { maker in
            maker.bottom.equalTo(tryForFreeLabel.snp.top).offset(-CGFloat.margin4)
            maker.leading.equalToSuperview().offset(CGFloat.margin16)
        }

        titleDescription.setContentHuggingPriority(.required, for: .horizontal)
        titleDescription.font = .headline2
        titleDescription.textColor = .themeLeah

        let description = NSMutableAttributedString()
        description.append(
            NSAttributedString(string: "premium.cell.description1".localized + " ", attributes: [.font: UIFont.headline2, .foregroundColor: UIColor.themeLeah])
        )
        description.append(
            NSAttributedString(string: "premium.cell.description2".localized, attributes: [.font: UIFont.headline2, .foregroundColor: UIColor.themeYellowD])
        )

        titleDescription.attributedText = description
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension MainSettingsPremiumCell {
    func bind(onTap _: @escaping () -> Void) {}
}
