import UIKit
import ThemeKit
import UniswapKit
import HUD
import RxSwift
import RxCocoa
import SectionsTableView
import ComponentKit

class SwapSettingsViewController: ThemeViewController {
    private let animationDuration: TimeInterval = 0.2
    private let disposeBag = DisposeBag()

    private let dataSourceManager: ISwapDataSourceManager
    private let tableView = SectionsTableView(style: .grouped)

    private let chooseServiceCell = B2Cell()
    private var dataSource: ISwapSettingsDataSource?

    private var isLoaded: Bool = false

    init(dataSourceManager: ISwapDataSourceManager) {
        self.dataSourceManager = dataSourceManager

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "swap.advanced_settings".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(didTapCancel))


        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
//        tableView.allowsSelection = false
        tableView.keyboardDismissMode = .onDrag
        tableView.sectionDataSource = self

        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)
        tableView.registerHeaderFooter(forClass: BottomDescriptionHeaderFooterView.self)

        chooseServiceCell.title = "swap.service".localized
        chooseServiceCell.valueColor = .themeLeah
        chooseServiceCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)

        subscribe(disposeBag, dataSourceManager.dataSourceUpdated) { [weak self] _ in self?.updateDataSource() }
        updateDataSource()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        isLoaded = true
    }

    private func sync(providerName: String?) {
        chooseServiceCell.value = providerName
    }

    @objc private func didTapCancel() {
        dismiss(animated: true)
    }

    private func updateDataSource() {
        dataSource = dataSourceManager.settingsDataSource

        dataSource?.onReload = { [weak self] in self?.reloadTable() }
        dataSource?.onClose = { [weak self] in self?.didTapCancel() }
        dataSource?.onOpen = { [weak self] viewController in self?.present(viewController, animated: true) }

        if isLoaded {
            tableView.reload()
        } else {
            tableView.buildSections()
        }
    }

    private func reloadTable() {
        UIView.animate(withDuration: animationDuration) {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }

}

extension SwapSettingsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        if let dataSource = dataSource {
            sections.append(contentsOf: dataSource.buildSections())
        }

        return sections
    }

}

