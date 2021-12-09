import UIKit
import SectionsTableView
import ThemeKit
import RxSwift
import ComponentKit

class EvmNetworkViewController: ThemeViewController {
    private let viewModel: EvmNetworkViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private var isLoaded = false

    private var sectionViewItems = [EvmNetworkViewModel.SectionViewItem]()

    init(viewModel: EvmNetworkViewModel) {
        self.viewModel = viewModel

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.title

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.registerCell(forClass: F4Cell.self)
        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)
        tableView.registerHeaderFooter(forClass: TopDescriptionHeaderFooterView.self)
        tableView.sectionDataSource = self

        subscribe(disposeBag, viewModel.sectionViewItemsDriver) { [weak self] sectionViewItems in
            self?.sectionViewItems = sectionViewItems

            self?.reloadTable()
        }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
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

extension EvmNetworkViewController: SectionsDataSource {

    private func header(text: String) -> ViewState<SubtitleHeaderFooterView> {
        .cellType(
                hash: text,
                binder: { $0.bind(text: text) },
                dynamicHeight: { _ in SubtitleHeaderFooterView.height }
        )
    }

    private func section(sectionViewItem: EvmNetworkViewModel.SectionViewItem) -> SectionProtocol {
        let footerState: ViewState<TopDescriptionHeaderFooterView> = sectionViewItem.description.flatMap { descriptionText in
            .cellType(hash: "bottom_description", binder: { view in
                view.bind(text: descriptionText)
            }, dynamicHeight: { [weak self] _ in
                if let containerWidth = self?.tableView.bounds.width {
                    return TopDescriptionHeaderFooterView.height(containerWidth: containerWidth, text: descriptionText)
                } else {
                    return 0
                }
            })
        } ?? .margin(height: .margin32)

        return Section(
                id: sectionViewItem.title,
                headerState: header(text: sectionViewItem.title),
                footerState: footerState,
                rows: sectionViewItem.viewItems.enumerated().map { index, viewItem in
                    let isFirst = index == 0
                    let isLast = index == sectionViewItem.viewItems.count - 1

                    return Row<F4Cell>(
                            id: viewItem.id,
                            hash: "\(viewItem.selected)",
                            height: .heightDoubleLineCell,
                            bind: { cell, _ in
                                cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                                cell.title = viewItem.name
                                cell.subtitle = viewItem.url
                                cell.valueImage = viewItem.selected ? UIImage(named: "check_1_20")?.withRenderingMode(.alwaysTemplate) : nil
                                cell.valueImageTintColor = .themeRemus
                            },
                            action: { [weak self] _ in
                                self?.viewModel.onSelectViewItem(id: viewItem.id)
                            }
                    )
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        [Section(id: "margin", headerState: .margin(height: .margin12))] + sectionViewItems.map { section(sectionViewItem: $0) }
    }

}
