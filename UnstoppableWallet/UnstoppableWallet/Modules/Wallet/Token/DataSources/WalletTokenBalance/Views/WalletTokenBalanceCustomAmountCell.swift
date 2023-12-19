import ComponentKit
import UIKit

class WalletTokenBalanceCustomAmountCell: BaseSelectableThemeCell {
    override public init(style _: UITableViewCell.CellStyle, reuseIdentifier _: String?) {
        super.init(style: .default, reuseIdentifier: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(title: String, amount: String?, dimmed: Bool) {
        let valueColor: UIColor = dimmed ? .themeGray50 : .themeLeah

        let elements: [CellBuilderNew.CellElement] = [
            .textElement(text: .subhead2(title), parameters: .allCompression),
            .margin8,
            .image20 { component in
                component.imageView.image = UIImage(named: "circle_information_20")?.withTintColor(.themeGray)
            },
            .textElement(text: .subhead2(amount, color: valueColor), parameters: [.rightAlignment]),
        ]

        CellBuilderNew.buildStatic(cell: self, rootElement: .hStack(elements))
    }
}
