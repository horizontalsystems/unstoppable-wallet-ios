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

        titleView.bind(
                title: config.title,
                subtitle: config.subtitle,
                image: config.icon,
                tintColor: config.iconTint
        )
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

        tableView.registerCell(forClass: F4Cell.self)
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

    private func onTap(index: Int) {
        if currentIndexes.contains(index) {
            currentIndexes.remove(index)
        } else {
            currentIndexes.insert(index)
        }

        tableView.reload(animated: true)
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

                        return Row<F4Cell>(
                                id: "item_\(index)",
                                hash: "\(selected)",
                                height: .heightDoubleLineCell,
                                autoDeselect: true,
                                bind: { cell, _ in
                                    cell.set(backgroundStyle: .transparent, isFirst: isFirst, isLast: isLast)
                                    cell.title = viewItem.title
                                    cell.subtitle = viewItem.subtitle
                                    cell.valueImageTintColor = .themeJacob
                                    cell.valueImage = selected ? UIImage(named: "check_1_20")?.withRenderingMode(.alwaysTemplate) : nil
                                },
                                action: { [weak self] _ in
                                    self?.onTap(index: index)
                                }
                        )
                    }
            )
        ]
    }

}

extension BottomMultiSelectorViewController {

    struct Config {
        let icon: UIImage?
        let iconTint: UIColor?
        let title: String
        let subtitle: String
        let description: String?
        let selectedIndexes: [Int]
        let viewItems: [ViewItem]
    }

    struct ViewItem {
        let title: String
        let subtitle: String
    }

}
