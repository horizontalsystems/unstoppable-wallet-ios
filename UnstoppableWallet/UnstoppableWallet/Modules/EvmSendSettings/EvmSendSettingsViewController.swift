import ComponentKit
import RxCocoa
import RxSwift
import SectionsTableView
import SnapKit
import ThemeKit
import UIKit

class EvmSendSettingsViewController: ThemeViewController {
    private let disposeBag = DisposeBag()

    private let viewModel: EvmSendSettingsViewModel
    private let dataSources: [IEvmSendSettingsDataSource]
    private let tableView = SectionsTableView(style: .grouped)
    private let cautionCell = TitledHighlightedDescriptionCell()

    private var loaded = false

    init(viewModel: EvmSendSettingsViewModel, dataSources: [IEvmSendSettingsDataSource]) {
        self.viewModel = viewModel
        self.dataSources = dataSources

        super.init()

        for dataSource in dataSources {
            dataSource.tableView = tableView

            dataSource.onOpenInfo = { [weak self] title, description in
                self?.openInfo(title: title, description: description)
            }

            dataSource.onUpdateAlteredState = { [weak self] in
                self?.syncResetButton()
            }
        }
    }

    private func syncResetButton() {
        for dataSource in dataSources {
            if dataSource.altered {
                navigationItem.leftBarButtonItem?.isEnabled = true
                return
            }
        }

        navigationItem.leftBarButtonItem?.isEnabled = false
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "fee_settings".localized
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.reset".localized, style: .done, target: self, action: #selector(onTapReset))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .done, target: self, action: #selector(onTapDone))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delaysContentTouches = false

        tableView.registerCell(forClass: TitledHighlightedDescriptionCell.self)
        tableView.sectionDataSource = self

        dataSources.forEach { $0.viewDidLoad() }

        subscribe(disposeBag, viewModel.cautionDriver) { [weak self] in self?.handle(caution: $0) }

        tableView.buildSections()
        syncResetButton()

        loaded = true
    }

    @objc private func onTapReset() {
        dataSources.forEach { $0.onTapReset() }
    }

    @objc private func onTapDone() {
        dismiss(animated: true)
    }

    private func openInfo(title: String, description: String) {
        let viewController = BottomSheetModule.description(title: title, text: description)
        present(viewController, animated: true)
    }

    private func handle(caution: TitledCaution?) {
        cautionCell.isVisible = caution != nil

        if let caution {
            cautionCell.bind(caution: caution)
        }

        if loaded {
            UIView.animate(withDuration: 0.15) {
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }
        }
    }
}

extension EvmSendSettingsViewController: SectionsDataSource {
    func buildSections() -> [SectionProtocol] {
        let dataSourceSections = dataSources.map(\.buildSections).reduce([], +)

        let cautionsSections: [SectionProtocol] = [
            Section(
                id: "caution",
                headerState: .margin(height: .margin32),
                rows: [
                    StaticRow(
                        cell: cautionCell,
                        id: "caution",
                        dynamicHeight: { [weak self] containerWidth in
                            self?.cautionCell.cellHeight(containerWidth: containerWidth) ?? 0
                        }
                    ),
                ]
            ),
        ]

        return dataSourceSections + cautionsSections
    }
}
