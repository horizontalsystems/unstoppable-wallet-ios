import UIKit
import SnapKit

class AdditionalDataCell: UITableViewCell {
    static let height: CGFloat = AdditionalDataView.height

    private let additionalDataView = AdditionalDataView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(additionalDataView)
        additionalDataView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(title: String?, value: String?, highlighted: Bool = false) {
        additionalDataView.bind(title: title, value: value)

        additionalDataView.setValue(color: highlighted ? .themeOz : .themeGray)
    }

    func set(valueColor: UIColor) {
        additionalDataView.setValue(color: valueColor)
    }

    var title: String? {
        get { additionalDataView.title }
        set { additionalDataView.title = newValue }
    }

    var value: String? {
        get { additionalDataView.value }
        set { additionalDataView.value = newValue }
    }

}
