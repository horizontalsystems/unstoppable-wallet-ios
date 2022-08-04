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
    private let doneButton = PrimaryButton()

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

        titleView.title = config.title

        switch config.icon {
        case .local(let name):
            titleView.image = UIImage(named: name)
        case .remote(let url, let placeholder):
            titleView.set(imageUrl: url, placeholder: placeholder.flatMap { UIImage(named: $0) })
        }

        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        var lastView: UIView = titleView
        var lastMargin: CGFloat = 0

        if let description = config.description {
            let descriptionView = HighlightedDescriptionView()

            view.addSubview(descriptionView)
            descriptionView.snp.makeConstraints { maker in
                maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
                maker.top.equalTo(titleView.snp.bottom)
            }

            descriptionView.text = description

            lastView = descriptionView
            lastMargin = .margin12
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(lastView.snp.bottom).offset(lastMargin)
        }

        tableView.sectionDataSource = self

        view.addSubview(doneButton)
        doneButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalTo(tableView.snp.bottom).offset(CGFloat.margin24)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin24)
        }

        doneButton.set(style: .yellow)
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
        if config.allowEmpty {
            doneButton.isEnabled = true
        } else {
            doneButton.isEnabled = !currentIndexes.isEmpty
        }
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

                        return CellBuilderNew.row(
                                rootElement: .hStack([
                                    .image24 { component in
                                        if let icon = viewItem.icon {
                                            switch icon {
                                            case .local(let name):
                                                component.imageView.image = UIImage(named: name)
                                            case .remote(let url, let placeholder):
                                                component.setImage(urlString: url, placeholder: placeholder.flatMap { UIImage(named: $0) })
                                            }
                                            component.isHidden = false
                                        } else {
                                            component.isHidden = true
                                        }
                                    },
                                    .vStackCentered([
                                        .text { component in
                                            component.font = .body
                                            component.textColor = .themeLeah
                                            component.text = viewItem.title
                                        },
                                        .margin(3),
                                        .text { component in
                                            component.font = .subhead2
                                            component.textColor = .themeGray
                                            component.lineBreakMode = .byTruncatingMiddle
                                            component.text = viewItem.subtitle
                                        }
                                    ]),
                                    .switch { [weak self] component in
                                        component.switchView.isOn = selected
                                        component.onSwitch = { self?.onToggle(index: index, isOn: $0) }
                                    }
                                ]),
                                tableView: tableView,
                                id: "item_\(index)",
                                hash: "\(selected)",
                                height: .heightDoubleLineCell,
                                autoDeselect: true,
                                bind: { cell in
                                    cell.set(backgroundStyle: .bordered, isFirst: isFirst, isLast: isLast)
                                },
                                action: viewItem.copyableString.map { string in
                                    { CopyHelper.copyAndNotify(value: string) }
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
        let description: String?
        let allowEmpty: Bool
        let selectedIndexes: [Int]
        let viewItems: [ViewItem]
    }

    struct ViewItem {
        let icon: IconStyle?
        let title: String
        let subtitle: String
        let copyableString: String?

        init(icon: IconStyle? = nil, title: String, subtitle: String, copyableString: String? = nil) {
            self.icon = icon
            self.title  = title
            self.subtitle = subtitle
            self.copyableString = copyableString
        }
    }

    enum IconStyle {
        case local(name: String)
        case remote(url: String, placeholder: String?)
    }

}
