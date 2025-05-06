import ComponentKit
import SnapKit
import ThemeKit
import UIKit

class MainSettingsPremiumCell: UITableViewCell {
    public static let height: CGFloat = 130

    private let cardView = CardView(insets: .zero)

    private let titleLabel = UILabel()

    private let bottomStackView = UIStackView()
    private let titleDescription = UILabel()
    private let tryForFreeLabel = UILabel()

    private let boxImageView = UIImageView()

    private let radialBackgroundView = RadialBackgroundView(background: .themeHelsing)

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
        titleLabel.textColor = .themeJacob
        titleLabel.text = "premium.cell.title".localized

        cardView.contentView.addSubview(bottomStackView)
        bottomStackView.snp.makeConstraints { maker in
            maker.bottom.equalToSuperview().inset(CGFloat.margin16)
            maker.leading.equalToSuperview().offset(CGFloat.margin16)
            maker.trailing.equalTo(boxImageView.snp.leading).offset(-CGFloat.margin16)
        }

        bottomStackView.axis = .vertical
        bottomStackView.spacing = CGFloat.margin4

        bottomStackView.addArrangedSubview(titleDescription)

        titleDescription.setContentHuggingPriority(.required, for: .horizontal)
        titleDescription.font = .subhead1
        titleDescription.numberOfLines = 0
        titleDescription.textColor = .themeLeah

        titleDescription.text = "premium.cell.description".localized("premium.cell.description.key".localized)

        bottomStackView.addArrangedSubview(tryForFreeLabel)

        tryForFreeLabel.setContentHuggingPriority(.required, for: .horizontal)
        tryForFreeLabel.font = .captionSB
        tryForFreeLabel.textColor = .themeGreenD
        tryForFreeLabel.text = "premium.cell.try".localized
        tryForFreeLabel.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension MainSettingsPremiumCell {
    func bind(offerTitle: String?) {
        guard let title = offerTitle else {
            tryForFreeLabel.isHidden = true
            return
        }

        tryForFreeLabel.isHidden = false
        tryForFreeLabel.text = title
    }
}
