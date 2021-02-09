import UIKit
import SnapKit
import ThemeKit

class RateTopListCell: BaseSelectableThemeCell {
    private let rankLabel = UILabel()
    private let titleLabel = UILabel()
    private let coinLabel = UILabel()
    private let rightView = RateListChangingCellView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(rankLabel)
        rankLabel.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
            maker.width.equalTo(56)
        }

        rankLabel.textAlignment = .center
        rankLabel.font = .captionSB
        rankLabel.textColor = .themeGray

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(rankLabel.snp.trailing)
            maker.top.equalToSuperview().offset(10)
        }

        titleLabel.font = .body
        titleLabel.textColor = .themeOz

        contentView.addSubview(coinLabel)
        coinLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(titleLabel)
            maker.bottom.equalToSuperview().inset(CGFloat.margin2x)
        }

        coinLabel.font = .subhead2
        coinLabel.textColor = .themeGray

        contentView.addSubview(rightView)
        rightView.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin1x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(viewItem: RateTopListModule.ViewItem) {
        rankLabel.text = "\(viewItem.rank)"
        titleLabel.text = viewItem.coinTitle
        coinLabel.text = viewItem.coinCode

        rightView.bind(viewItem: viewItem.rate)
    }

    func bind(rank: Int, coinCode: String, coinName: String, rate: String, diff: Decimal) {
        rankLabel.text = "\(rank)"
        titleLabel.text = coinName
        coinLabel.text = coinCode

        rightView.bind(rate: rate, diff: diff)
    }

}
