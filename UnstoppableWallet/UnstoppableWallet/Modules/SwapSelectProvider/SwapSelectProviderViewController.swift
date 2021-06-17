import UIKit
import SectionsTableView
import ThemeKit
import RxSwift
import ComponentKit

class SwapSelectProviderViewController: ThemeViewController {
    private let viewModel: SwapSelectProviderViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private var isLoaded = false

    private var viewItems = [SwapSelectProviderViewModel.ViewItem]()

    init(viewModel: SwapSelectProviderViewModel) {
        self.viewModel = viewModel

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "swap.service.title".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.registerCell(forClass: A4Cell.self)
        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)
        tableView.sectionDataSource = self

        subscribe(disposeBag, viewModel.sectionViewItemsDriver) { [weak self] viewItems in
            self?.viewItems = viewItems

            self?.reloadTable()
        }

        tableView.buildSections()

        isLoaded = true
    }

    private func reloadTable() {
        guard isLoaded else {
            return
        }

        tableView.reload(animated: true)
    }

}

extension SwapSelectProviderViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [Section(
                id: "theme",
                headerState: .margin(height: .margin12),
                footerState: .margin(height: .margin8x),
                rows: viewItems.enumerated().map { index, viewItem in
                    let isFirst = index == 0
                    let isLast = index == viewItems.count - 1

                    return Row<A4Cell>(
                            id: viewItem.title,
                            hash: "\(viewItem.selected)",
                            height: .heightCell48,
                            autoDeselect: true,
                            bind: { cell, _ in
                                cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                                cell.title = viewItem.title
                                cell.titleImage = UIImage(named: viewItem.icon)
                                cell.titleImageTintColor = .themeGray
                                cell.valueImage = viewItem.selected ? UIImage(named: "check_1_20")?.withRenderingMode(.alwaysTemplate) : nil
                                cell.valueImageTintColor = .themeJacob
                            },
                            action: { [weak self] _ in
                                self?.viewModel.onSelect(index: index)
                            }
                    )
                }
        )]
    }

}
