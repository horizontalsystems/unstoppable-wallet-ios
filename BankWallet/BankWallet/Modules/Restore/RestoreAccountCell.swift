import UIKit
import SnapKit

class RestoreAccountCell: CardCell {
    private static let topMargin: CGFloat = 10
    private static let bottomMargin = CGFloat.margin3x
    private static let nameHeight: CGFloat = 20

    private let nameLabel = UILabel()
    private let coinsLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        nameLabel.font = .cryptoHeadline2
        nameLabel.textColor = .appOz
        clippingView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin3x)
            maker.top.equalToSuperview().offset(RestoreAccountCell.topMargin)
        }

        coinsLabel.font = .cryptoSubhead2
        coinsLabel.textColor = .appGray
        coinsLabel.numberOfLines = 0
        clippingView.addSubview(coinsLabel)
        coinsLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin3x)
            maker.top.equalTo(nameLabel.snp.bottom).offset(CGFloat.margin2x)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(accountType: AccountTypeViewItem) {
        nameLabel.text = "restore.item_title".localized(accountType.title)
        coinsLabel.text = accountType.coinCodes
    }

}

extension RestoreAccountCell {

    static func height(containerWidth: CGFloat, accountType: AccountTypeViewItem) -> CGFloat {
        let coinCodesTextHeight = accountType.coinCodes.height(
                forContainerWidth: containerWidth - CardCell.cardMargins - 2 * CGFloat.margin3x, font: .cryptoSubhead2
        )

        return RestoreAccountCell.topMargin + nameHeight + CGFloat.margin2x + coinCodesTextHeight + RestoreAccountCell.bottomMargin
    }

}
