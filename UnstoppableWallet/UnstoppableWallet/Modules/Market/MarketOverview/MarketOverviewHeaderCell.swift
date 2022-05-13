import UIKit
import SnapKit
import ComponentKit

class MarketOverviewHeaderCell: BaseThemeCell {
    private let leftView = LeftAView()
    private let buttonWrapper = UIView()
    private let rightButton = SelectorButton()
    private let seeAllButton = ThemeButton()

    var onSelect: ((Int) -> ())? {
        didSet {
            rightButton.onSelect = onSelect
        }
    }
    var onSeeAll: (() -> ())?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        layout(leftView: leftView, rightView: buttonWrapper)

        buttonWrapper.addSubview(rightButton)
        rightButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
            maker.height.equalTo(28)
        }

        buttonWrapper.addSubview(seeAllButton)
        seeAllButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
            maker.height.equalTo(28)
        }

        seeAllButton.isHidden = true
        seeAllButton.apply(style: .secondaryDefault)
        seeAllButton.setTitle("market.top.section.header.see_all".localized, for: .normal)
        seeAllButton.addTarget(self, action: #selector(onTapSeeAll), for: .touchUpInside)
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

    @objc func onTapSeeAll() {
        onSeeAll?()
    }

    var buttonMode: ButtonMode = .seeAll {
        didSet {
            rightButton.isHidden = true
            seeAllButton.isHidden = true
            rightButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
            seeAllButton.setContentHuggingPriority(.defaultLow, for: .horizontal)

            switch buttonMode {
            case .selector:
                rightButton.isHidden = false
                rightButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            case .seeAll:
                seeAllButton.isHidden = false
                seeAllButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            case .none: return
            }
        }
    }

}

extension MarketOverviewHeaderCell {

    enum ButtonMode {
        case selector
        case seeAll
        case none
    }

}
