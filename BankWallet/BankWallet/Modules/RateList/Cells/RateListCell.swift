import UIKit
import SnapKit
import ThemeKit

class RateListCell: ThemeCell {
    private let leftView = LeftImageCellView()
    private let middleView = DoubleLineCellView()
    private let rightView = RateListChangingCellView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(leftView)
        leftView.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.equalToSuperview().offset(CGFloat.margin2x)
        }

        contentView.addSubview(middleView)
        middleView.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.equalTo(leftView.snp.trailing)
        }

        contentView.addSubview(rightView)
        rightView.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.equalTo(middleView.snp.trailing)
            maker.trailing.equalToSuperview().inset(CGFloat.margin2x)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(viewItem: RateViewItem, last: Bool = false) {
        super.bind(last: last)

        leftView.bind(image: UIImage(named: "\(viewItem.coin.code.lowercased())")?.tinted(with: .themeGray))
        middleView.bind(title: viewItem.coin.code, subtitle: viewItem.coin.title)

        let rateString: String?
        let rateColor: UIColor
        if let rate = viewItem.rate {
            rateString = ValueFormatter.instance.format(currencyValue: rate, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false)
            rateColor = viewItem.rateExpired ? .themeGray50 : .themeLeah
        } else {
            rateString = "n/a".localized
            rateColor = .themeGray50
        }

        rightView.bind(rate: rateString, rateColor: rateColor, diff: !viewItem.rateExpired ? viewItem.diff : nil)
    }

}
