import UIKit
import SnapKit
import ThemeKit

class SendConfirmationAmountCell: ThemeCell {

    private let amountInfoView = AmountInfoView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = .themeLawrence
        backgroundColor = .clear
        selectionStyle = .none

        addSubview(amountInfoView)

        amountInfoView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(primaryAmountInfo: AmountInfo, secondaryAmountInfo: AmountInfo?) {
        super.bind(showDisclosure: false, last: false)
        amountInfoView.bind(primaryAmountInfo: primaryAmountInfo, secondaryAmountInfo: secondaryAmountInfo)
    }

}
