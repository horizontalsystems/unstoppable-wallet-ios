import UIKit
import ThemeKit
import SnapKit
import SectionsTableView
import RxSwift
import RxCocoa
import ComponentKit

protocol ISendSettingsDataSource: AnyObject {
    var tableView: SectionsTableView? { get set }
    var onOpenInfo: ((String, String) -> ())? { get set }
    var present: ((UIViewController) -> ())? { get set }
    var onUpdateAlteredState: (() -> ())? { get set }
    var onCaution: ((TitledCaution?) -> ())? { get set }

    var altered: Bool { get }
    var buildSections: [SectionProtocol] { get }

    func onTapReset()
    func viewDidLoad()
}

class SendSettingsViewController: ThemeViewController {
    private let disposeBag = DisposeBag()

    private let dataSources: [ISendSettingsDataSource]
    private let tableView = SectionsTableView(style: .grouped)
    private let cautionCell = TitledHighlightedDescriptionCell()

    private var loaded = false

    init(dataSources: [ISendSettingsDataSource]) {
        self.dataSources = dataSources

        super.init()

        for dataSource in dataSources {
            dataSource.tableView = tableView

            dataSource.onOpenInfo = { [weak self] title, description in
                self?.openInfo(title: title, description: description)
            }

            dataSource.present = { [weak self] viewController in
                self?.present(viewController, animated: true)
            }

            dataSource.onUpdateAlteredState = { [weak self] in
                self?.syncResetButton()
            }

            dataSource.onCaution = { [weak self] caution in
                self?.handle(caution: caution)
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

    required public init?(coder aDecoder: NSCoder) {
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

        tableView.buildSections()
        syncResetButton()
        handle(caution: nil)
        dataSources.forEach { $0.viewDidLoad() }

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

        if let caution = caution {
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

extension SendSettingsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let dataSourceSections = dataSources.map{ $0.buildSections }.reduce([], +)

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
                        )
                    ]
            )
        ]

        return dataSourceSections + cautionsSections
    }

}
