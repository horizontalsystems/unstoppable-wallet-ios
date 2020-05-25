import UIKit
import ThemeKit

class AlertItemCell: ThemeCell {
    private let label = UILabel()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        label.font = .body
        label.textAlignment = .center
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(viewItem: AlertViewItem) {
        super.bind()

        label.text = viewItem.text
        label.textColor = viewItem.selected ? .themeJacob : .themeOz
    }

}
