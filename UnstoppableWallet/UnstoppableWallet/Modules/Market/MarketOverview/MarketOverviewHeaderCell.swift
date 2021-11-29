import UIKit
import SnapKit
import ComponentKit

class MarketOverviewHeaderCell: BaseThemeCell {
    private let leftView = LeftAView()
    private let buttonWrapper = UIView()
    private let rightButton = SelectorButton()

    var onSelect: ((Int) -> ())? {
        didSet {
            rightButton.onSelect = onSelect
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        layout(leftView: leftView, rightView: buttonWrapper)

        buttonWrapper.addSubview(rightButton)
        rightButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
            maker.height.equalTo(28)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var title: String? {
        get { leftView.text }
        set { leftView.text = newValue }
    }

    var titleImage: UIImage? {
        get { leftView.image }
        set { leftView.image = newValue }
    }

    func set(titleImageSize: CGFloat) {
        leftView.set(imageSize: titleImageSize)
    }

    var currentIndex: Int {
        rightButton.currentIndex
    }

    func set(values: [String]) {
        rightButton.set(items: values)
    }

    func setSelected(index: Int) {
        rightButton.setSelected(index: index)
    }

}
