import UIKit
import SnapKit
import ThemeKit
import ComponentKit

class SendConfirmationAmountCell: BaseThemeCell {
    static let height: CGFloat = 72

    private let amountInfoView = AmountInfoView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        wrapperView.addSubview(amountInfoView)
        amountInfoView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(primaryAmountInfo: AmountInfo, secondaryAmountInfo: AmountInfo?) {
        amountInfoView.bind(primaryAmountInfo: primaryAmountInfo, secondaryAmountInfo: secondaryAmountInfo)
    }

}
