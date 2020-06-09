import UIKit
import SnapKit
import ThemeKit

class RateTopListCell: ClaudeThemeCell {
    private let orderLabel = UILabel()
    private let titleLabel = UILabel()
    private let coinLabel = UILabel()
    private let rightView = RateListChangingCellView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(orderLabel)
        orderLabel.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
            maker.width.equalTo(56)
        }

        orderLabel.textAlignment = .center
        orderLabel.font = .captionSB
        orderLabel.textColor = .themeGray

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(orderLabel.snp.trailing)
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

    func bind(order: Int, viewItem: RateTopListModule.ViewItem, last: Bool = false) {
        super.bind(last: last)

        orderLabel.text = "\(order)"
        titleLabel.text = viewItem.coinTitle
        coinLabel.text = viewItem.coinCode

        rightView.bind(viewItem: viewItem.rate)
    }

}
