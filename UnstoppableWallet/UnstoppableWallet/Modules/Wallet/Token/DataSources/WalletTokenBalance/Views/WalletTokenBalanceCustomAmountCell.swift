import UIKit
import ComponentKit

class WalletTokenBalanceCustomAmountCell: BaseSelectableThemeCell {

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(item: WalletTokenBalanceViewModel.BalanceCustomStateViewItem) {
        let valueColor: UIColor = (item.amountValue?.dimmed ?? false) ? .themeGray50 : .themeLeah

        let elements: [CellBuilderNew.CellElement] = [
            .textElement(text: .subhead2(item.title), parameters: .allCompression),
            .margin8,
            .image20 {  component in
                component.imageView.image = UIImage(named: "circle_information_20")?.withTintColor(.themeGray)
            },
            .textElement(text: .subhead2(item.amountValue?.text, color: valueColor), parameters: [.rightAlignment]),
        ]

        CellBuilderNew.buildStatic(cell: self, rootElement: .hStack(elements))
    }

}
