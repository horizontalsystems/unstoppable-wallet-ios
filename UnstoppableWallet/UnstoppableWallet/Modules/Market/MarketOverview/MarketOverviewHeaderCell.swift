import UIKit
import SnapKit
import ComponentKit

class MarketOverviewHeaderCell: BaseThemeCell {
    private let leftImage = ImageComponent(size: .iconSize20)
    private let titleText = TextComponent()
    private let buttonWrapper = UIView()
    private let rightButton = SelectorButton()
    private let seeAllButton = SecondaryButton()

    var onSelect: ((Int) -> ())? {
        didSet {
            rightButton.onSelect = onSelect
        }
    }
    var onSeeAll: (() -> ())?
    var onTapTitle: (() -> ())?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        wrapperView.addSubview(leftImage)
        leftImage.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
        }

        wrapperView.addSubview(titleText)
        titleText.snp.makeConstraints { maker in
            maker.leading.equalTo(leftImage.snp.trailing).offset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
        }

        wrapperView.addSubview(buttonWrapper)
        buttonWrapper.snp.makeConstraints { maker in
            maker.leading.equalTo(titleText.snp.trailing).offset(CGFloat.margin16)
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.bottom.equalToSuperview()
        }

        let leftButton = UIButton()
        wrapperView.addSubview(leftButton)
        leftButton.snp.makeConstraints { maker in
            maker.edges.equalTo(titleText)
        }

        leftButton.addTarget(self, action: #selector(onTapLeftView), for: .touchUpInside)

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
        seeAllButton.set(style: .default)
        seeAllButton.setTitle("market.top.section.header.see_all".localized, for: .normal)
        seeAllButton.addTarget(self, action: #selector(onTapSeeAll), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapLeftView() {
        onTapTitle?()
    }

    var title: String? {
        get { titleText.text }
        set { titleText.text = newValue }
    }

    var titleImage: UIImage? {
        get { leftImage.imageView.image }
        set { leftImage.imageView.image = newValue }
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
