import UIKit

class TitleManageAccountCell: BaseManageAccountCell {
    private static let walletImage = UIImage(named: "wallet_24")?.withRenderingMode(.alwaysTemplate)
    private static let walletImageLeftMargin: CGFloat = .margin4x
    private static let textsHorizontalMargin: CGFloat = .margin4x
    private static let titleTopMargin: CGFloat = 10
    private static let titleBottomMargin: CGFloat = 5
    private static let coinsBottomMargin: CGFloat = .margin2x
    private static let titleFont: UIFont = .headline2
    private static let coinsFont: UIFont = .subhead2

    private let walletImageView = UIImageView()
    private let titleLabel = UILabel()
    private let coinLabel = UILabel()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        contentHolder.addSubview(walletImageView)
        walletImageView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(TitleManageAccountCell.walletImageLeftMargin)
        }

        walletImageView.setContentHuggingPriority(.required, for: .horizontal)
        walletImageView.setContentHuggingPriority(.required, for: .vertical)
        walletImageView.image = TitleManageAccountCell.walletImage

        contentHolder.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(walletImageView.snp.trailing).offset(TitleManageAccountCell.textsHorizontalMargin)
            maker.top.equalToSuperview().offset(TitleManageAccountCell.titleTopMargin)
            maker.trailing.equalToSuperview().inset(TitleManageAccountCell.textsHorizontalMargin)
        }

        titleLabel.textColor = .themeOz
        titleLabel.font = TitleManageAccountCell.titleFont

        contentHolder.addSubview(coinLabel)
        coinLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(titleLabel)
            maker.top.equalTo(titleLabel.snp.bottom).offset(TitleManageAccountCell.titleBottomMargin)
        }

        coinLabel.numberOfLines = 0
        coinLabel.textColor = .themeGray
        coinLabel.font = TitleManageAccountCell.coinsFont

    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(viewItem: ManageAccountViewItem, height: CGFloat) {
        super.bind(position: .top, highlighted: viewItem.highlighted, height: height)

        titleLabel.text = viewItem.title
        coinLabel.text = viewItem.coinCodes
        walletImageView.tintColor = viewItem.highlighted ? .themeJacob : .themeGray
    }

}

extension TitleManageAccountCell {

    static func height(forContainerWidth containerWidth: CGFloat, viewItem: ManageAccountViewItem) -> CGFloat {
        let contentWidth = BaseManageAccountCell.contentWidth(forContainerWidth: containerWidth)
        let textsWidth = contentWidth - walletImageLeftMargin - (walletImage?.size.width ?? 0) - textsHorizontalMargin * 2

        let titleHeight = viewItem.title.height(forContainerWidth: textsWidth, font: titleFont)
        let coinsHeight = viewItem.coinCodes.height(forContainerWidth: textsWidth, font: coinsFont)

        return titleTopMargin + titleHeight + titleBottomMargin + coinsHeight + coinsBottomMargin
    }

}
