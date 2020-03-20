import UIKit

class TitleManageAccountCell: BaseManageAccountCell {
    static let height: CGFloat = 60

    private let walletImageView = CoinIconImageView()
    private let titleLabel = UILabel()
    private let coinLabel = UILabel()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        contentHolder.addSubview(walletImageView)
        walletImageView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(CGFloat.margin6x)
        }
        walletImageView.image = UIImage(named: "Wallet Icon")?.withRenderingMode(.alwaysTemplate)

        contentHolder.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(walletImageView.snp.trailing).offset(CGFloat.margin4x)
            maker.top.equalToSuperview().offset(CGFloat.margin2x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        titleLabel.textColor = .themeOz
        titleLabel.font = .headline2

        contentHolder.addSubview(coinLabel)
        coinLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(titleLabel)
            maker.top.equalTo(titleLabel.snp.bottom).offset(3)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        coinLabel.textColor = .themeGray
        coinLabel.font = .subhead2

    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(viewItem: ManageAccountViewItem) {
        super.bind(position: .top, highlighted: viewItem.highlighted, height: TitleManageAccountCell.height)

        titleLabel.text = viewItem.title
        coinLabel.text = viewItem.coinCodes
        walletImageView.tintColor = viewItem.highlighted ? .themeJacob : .themeGray
    }

}
