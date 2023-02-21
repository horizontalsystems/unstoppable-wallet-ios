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
    private let config: SelectorModule.MultiConfig
    private weak var delegate: IBottomMultiSelectorDelegate?

    private let titleView = BottomSheetTitleView()
    private let tableView = SelfSizedSectionsTableView(style: .grouped)
    private let doneButton = PrimaryButton()

    private var currentIndexes = Set<Int>()
    private var didTapDone = false

    init(config: SelectorModule.MultiConfig, delegate: IBottomMultiSelectorDelegate) {
        self.config = config
        self.delegate = delegate

        for (index, viewItem) in config.viewItems.enumerated() {
            if viewItem.selected {
                currentIndexes.insert(index)
            }
        }

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
        titleView.bind(image: config.image, title: config.title, viewController: self)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(titleView.snp.bottom)
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

    private var descriptionRows: [RowProtocol] {
        guard let description = config.description else {
            return []
        }

        return [
            tableView.highlightedDescriptionRow(id: "description", text: description)
        ]
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "main",
                    headerState: .margin(height: config.description != nil ? 0 : .margin12),
                    rows: descriptionRows + config.viewItems.enumerated().map { index, viewItem in
                        SelectorModule.row(
                                viewItem: viewItem,
                                tableView: tableView,
                                isOn: currentIndexes.contains(index),
                                backgroundStyle: .bordered,
                                index: index,
                                isFirst: index == 0,
                                isLast: index == config.viewItems.count - 1
                        ) { [weak self] index, isOn in
                            self?.onToggle(index: index, isOn: isOn)
                        }
                    }
            )
        ]
    }

}
