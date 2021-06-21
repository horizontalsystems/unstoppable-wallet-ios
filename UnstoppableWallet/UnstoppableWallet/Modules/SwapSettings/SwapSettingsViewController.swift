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

    private let viewModel: SwapSettingsViewModel
    private let tableView = SectionsTableView(style: .grouped)

    private let chooseServiceCell = A2Cell()
    private var dataSource: ISwapSettingsDataSource?

    private var isLoaded: Bool = false

    init(viewModel: SwapSettingsViewModel) {
        self.viewModel = viewModel

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
        chooseServiceCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)

        subscribeToViewModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        isLoaded = true
    }

    @objc private func didTapCancel() {
        dismiss(animated: true)
    }

    private func didTapSelectProvider() {
        navigationController?.pushViewController(SwapSelectProviderModule.viewController(dataSourceManager: viewModel.swapDataSourceManager), animated: true)
    }

    private func subscribeToViewModel() {
        subscribe(disposeBag, viewModel.dataSourceUpdated) { [weak self] _ in
            self?.updateDataSource()
        }
        updateDataSource()
    }

    private func updateDataSource() {
        chooseServiceCell.value = viewModel.provider

        dataSource = viewModel.dataSource

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

        sections.append(Section(id: "provider",
                headerState: .margin(height: CGFloat.margin12),
                footerState: .margin(height: CGFloat.margin12),
                rows: [StaticRow(
                        cell: chooseServiceCell,
                        id: "provider-cell",
                        height: .heightCell48,
                        autoDeselect: true,
                        action: { [weak self] in
                            self?.didTapSelectProvider()
                        }
                )
                ]))

        if let dataSource = dataSource {
            sections.append(contentsOf: dataSource.buildSections())
        }

        return sections
    }

}

