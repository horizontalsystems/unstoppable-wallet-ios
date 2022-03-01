import UIKit
import ActionSheet
import ThemeKit
import SectionsTableView
import ComponentKit

protocol IBottomMultiSelectorDelegate: AnyObject {
    func bottomSelectorOnSelect(indexes: [Int])
    func bottomSelectorOnCancel()
}

class BottomMultiSelectorViewController: ThemeActionSheetController {
    private let config: Config
    private weak var delegate: IBottomMultiSelectorDelegate?

    private let titleView = BottomSheetTitleView()
    private let tableView = SelfSizedSectionsTableView(style: .grouped)
    private let doneButton = ThemeButton()

    private var currentIndexes: Set<Int>
    private var didTapDone = false

    init(config: Config, delegate: IBottomMultiSelectorDelegate) {
        self.config = config
        self.delegate = delegate

        currentIndexes = Set(config.selectedIndexes)

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.bind(title: config.title, subtitle: config.subtitle)
        switch config.icon {
        case .local(let icon, let tintColor):
            titleView.bind(image: icon, tintColor: tintColor)
        case .remote(let iconUrl, let iconPlaceholder):
            titleView.bind(imageUrl: iconUrl, placeholder: UIImage(named: iconPlaceholder))
        }

        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        var lastView: UIView = titleView

        if let description = config.description {
            let descriptionView = HighlightedDescriptionView()

            view.addSubview(descriptionView)
            descriptionView.snp.makeConstraints { maker in
                maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
                maker.top.equalTo(titleView.snp.bottom).offset(CGFloat.margin12)
            }

            descriptionView.text = description

            let separatorView = UIView()

            view.addSubview(separatorView)
            separatorView.snp.makeConstraints { maker in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(descriptionView.snp.bottom).offset(CGFloat.margin12)
                maker.height.equalTo(CGFloat.heightOneDp)
            }

            separatorView.backgroundColor = .themeSteel10

            lastView = separatorView
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(lastView.snp.bottom)
        }

        tableView.sectionDataSource = self

        view.addSubview(doneButton)
        doneButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(tableView.snp.bottom).offset(CGFloat.margin24)
            maker.bottom.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(CGFloat.heightButton)
        }

        doneButton.apply(style: .primaryYellow)
        doneButton.setTitle("button.done".localized, for: .normal)
        doneButton.addTarget(self, action: #selector(onTapDone), for: .touchUpInside)

        syncDoneButton()
        tableView.buildSections()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if !didTapDone {
            delegate?.bottomSelectorOnCancel()
        }
    }

    @objc private func onTapDone() {
        delegate?.bottomSelectorOnSelect(indexes: Array(currentIndexes))

        didTapDone = true
        dismiss(animated: true)
    }

    private func onToggle(index: Int, isOn: Bool) {
        if isOn {
            currentIndexes.insert(index)
        } else {
            currentIndexes.remove(index)
        }

        syncDoneButton()
    }

    private func syncDoneButton() {
        doneButton.isEnabled = !currentIndexes.isEmpty
    }

}

extension BottomMultiSelectorViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "main",
                    rows: config.viewItems.enumerated().map { index, viewItem in
                        let selected = currentIndexes.contains(index)
                        let isFirst = index == 0
                        let isLast = index == config.viewItems.count - 1

                        return CellBuilder.row(
                                elements: [.image24, .multiText, .switch],
                                tableView: tableView,
                                id: "item_\(index)",
                                hash: "\(selected)",
                                height: .heightDoubleLineCell,
                                bind: { cell in
                                    cell.set(backgroundStyle: .transparent, isFirst: isFirst, isLast: isLast)

                                    cell.bind(index: 0) { (component: ImageComponent) in
                                        if let iconName = viewItem.iconName {
                                            component.imageView.image = UIImage(named: iconName)
                                            component.isHidden = false
                                        } else {
                                            component.isHidden = true
                                        }
                                    }

                                    cell.bind(index: 1) { (component: MultiTextComponent) in
                                        component.set(style: .m1)
                                        component.title.set(style: .b2)
                                        component.subtitle.set(style: .d1)

                                        component.title.text = viewItem.title
                                        component.subtitle.text = viewItem.subtitle
                                        component.subtitle.lineBreakMode = .byTruncatingMiddle
                                    }

                                    cell.bind(index: 2) { (component: SwitchComponent) in
                                        component.switchView.isOn = selected
                                        component.onSwitch = { [weak self] in self?.onToggle(index: index, isOn: $0) }
                                    }
                                }
                        )
                    }
            )
        ]
    }

}

extension BottomMultiSelectorViewController {

    struct Config {
        let icon: IconStyle
        let title: String
        let subtitle: String
        let description: String?
        let selectedIndexes: [Int]
        let viewItems: [ViewItem]

        enum IconStyle {
            case local(icon: UIImage?, iconTint: UIColor?)
            case remote(iconUrl: String, placeholder: String)
        }
    }

    struct ViewItem {
        let iconName: String?
        let title: String
        let subtitle: String

        init(iconName: String? = nil, title: String, subtitle: String) {
            self.iconName = iconName
            self.title  = title
            self.subtitle = subtitle
        }
    }

}
