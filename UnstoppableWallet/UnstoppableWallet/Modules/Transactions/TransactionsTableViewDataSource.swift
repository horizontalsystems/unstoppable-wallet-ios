import Combine
import UIKit
import SnapKit
import RxSwift
import ThemeKit
import ComponentKit

class TransactionsTableViewDataSource: NSObject {
    private let viewModel: BaseTransactionsViewModel
    private let disposeBag = DisposeBag()

    private var sectionViewItems = [BaseTransactionsViewModel.SectionViewItem]()
    private var allLoaded = true
    private var loaded = false

    weak var viewController: UIViewController?
    private weak var tableView: UITableView?
    weak var delegate: ISectionDataSourceDelegate?

    init(viewModel: BaseTransactionsViewModel) {
        self.viewModel = viewModel
    }

    private func itemClicked(item: BaseTransactionsViewModel.ViewItem) {
        if let record = viewModel.record(uid: item.uid) {
            guard let module = TransactionInfoModule.instance(transactionRecord: record) else {
                return
            }

            viewController?.present(ThemeNavigationController(rootViewController: module), animated: true)
        }
    }

    private func color(valueType: BaseTransactionsViewModel.ValueType) -> UIColor {
        switch valueType {
        case .incoming: return .themeRemus
        case .outgoing: return .themeLucian
        case .neutral: return .themeLeah
        case .secondary: return .themeGray
        }
    }

    private func handle(viewData: BaseTransactionsViewModel.ViewData) {
        sectionViewItems = viewData.sectionViewItems

        if let allLoaded = viewData.allLoaded {
            self.allLoaded = allLoaded
        }

        guard let tableView, loaded else {
            return
        }

        if let updateInfo = viewData.updateInfo {
//            print("Update Item: \(updateInfo.sectionIndex)-\(updateInfo.index)")
            let indexPath = IndexPath(row: updateInfo.index, section: updateInfo.sectionIndex)
            let originalIndexPath = delegate?
                .originalIndexPath(tableView: tableView, dataSource: self, indexPath: indexPath) ?? indexPath

            if let cell = tableView.cellForRow(at: originalIndexPath) as? BaseThemeCell {
                cell.bind(rootElement: rootElement(viewItem: sectionViewItems[updateInfo.sectionIndex].viewItems[updateInfo.index]))
            }
        } else {
//            print("RELOAD TABLE VIEW")
            tableView.reloadData()
        }
    }

    private func sync(syncing: Bool) {
        // todo
    }

    private func rootElement(viewItem: BaseTransactionsViewModel.ViewItem) -> CellBuilderNew.CellElement {
        .hStack([
            .transactionImage { component in
                component.set(progress: viewItem.progress)

                switch viewItem.iconType {
                case .icon(let imageUrl, let placeholderImageName):
                    component.setImage(
                            urlString: imageUrl,
                            placeholder: UIImage(named: placeholderImageName)
                    )
                case .localIcon(let imageName):
                    component.set(image: imageName.flatMap { UIImage(named: $0)?.withTintColor(.themeLeah) })
                case let .doubleIcon(frontType, frontUrl, frontPlaceholder, backType, backUrl, backPlaceholder):
                    component.setDoubleImage(
                            frontType: frontType,
                            frontUrl: frontUrl,
                            frontPlaceholder: UIImage(named: frontPlaceholder),
                            backType: backType,
                            backUrl: backUrl,
                            backPlaceholder: UIImage(named: backPlaceholder)
                    )
                case .failedIcon:
                    component.set(image: UIImage(named: "warning_2_20")?.withTintColor(.themeLucian), contentMode: .center)
                }
            },
            .margin(10),
            .vStackCentered([
                .hStack([
                    .text { component in
                        component.font = .body
                        component.textColor = .themeLeah
                        component.setContentCompressionResistancePriority(.required, for: .horizontal)
                        component.text = viewItem.title
                    },
                    .text { [weak self] component in
                        if let primaryValue = viewItem.primaryValue, !primaryValue.text.isEmpty {
                            component.isHidden = false
                            component.font = .body
                            component.textColor = self?.color(valueType: primaryValue.type) ?? .themeLeah
                            component.textAlignment = .right
                            component.lineBreakMode = .byTruncatingMiddle
                            component.text = primaryValue.text
                        } else {
                            component.isHidden = true
                        }
                    },
                    .margin8,
                    .image20 { component in
                        component.isHidden = !viewItem.sentToSelf
                        component.imageView.image = UIImage(named: "arrow_return_20")?.withTintColor(.themeGray)
                    },
                    .margin(6),
                    .image20 { component in
                        if let locked = viewItem.locked {
                            component.imageView.image = locked ? UIImage(named: "lock_20")?.withTintColor(.themeGray) : UIImage(named: "unlock_20")?.withTintColor(.themeGray)
                            component.isHidden = false
                        } else {
                            component.isHidden = true
                        }
                    }
                ]),
                .margin(1),
                .hStack([
                    .text { component in
                        component.font = .subhead2
                        component.textColor = .themeGray
                        component.setContentCompressionResistancePriority(.required, for: .horizontal)
                        component.text = viewItem.subTitle
                    },
                    .text { [weak self] component in
                        if let secondaryValue = viewItem.secondaryValue, !secondaryValue.text.isEmpty {
                            component.isHidden = false
                            component.font = .subhead2
                            component.textColor = self?.color(valueType: secondaryValue.type) ?? .themeLeah
                            component.textAlignment = .right
                            component.lineBreakMode = .byTruncatingMiddle
                            component.text = secondaryValue.text
                        } else {
                            component.isHidden = true
                        }
                    }
                ])
            ])
        ])
    }

}

extension TransactionsTableViewDataSource: ISectionDataSource {

    func prepare(tableView: UITableView) {
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.delaysContentTouches = false

        tableView.registerCell(forClass: SpinnerCell.self)
        tableView.registerCell(forClass: EmptyCell.self)
        tableView.registerCell(forClass: PlaceholderCell.self)
        tableView.registerHeaderFooter(forClass: TransactionDateHeaderView.self)

        self.tableView = tableView

        subscribe(disposeBag, viewModel.viewDataDriver) { [weak self] in self?.handle(viewData: $0) }
        subscribe(disposeBag, viewModel.syncingDriver) { [weak self] in self?.sync(syncing: $0) }

        loaded = true
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        if sectionViewItems.isEmpty {
            return 1
        } else {
            return sectionViewItems.count + (allLoaded ? 0 : 1) + 1
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if sectionViewItems.isEmpty {
            return 1
        } else if section < sectionViewItems.count {
            return sectionViewItems[section].viewItems.count
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let originalIndexPath = delegate?.originalIndexPath(tableView: tableView, dataSource: self, indexPath: indexPath) ?? indexPath

        if sectionViewItems.isEmpty {
            return tableView.dequeueReusableCell(withIdentifier: String(describing: PlaceholderCell.self), for: originalIndexPath)
        } else if indexPath.section < sectionViewItems.count {
            return CellBuilderNew.preparedCell(
                    tableView: tableView,
                    indexPath: originalIndexPath,
                    selectable: true,
                    rootElement: rootElement(viewItem: sectionViewItems[indexPath.section].viewItems[indexPath.row]),
                    layoutMargins: UIEdgeInsets(top: 0, left: .margin6, bottom: 0, right: .margin16)
            )
        } else if indexPath.section == numberOfSections(in: tableView) - 1 {
            return tableView.dequeueReusableCell(withIdentifier: String(describing: EmptyCell.self), for: originalIndexPath)
        } else {
            return tableView.dequeueReusableCell(withIdentifier: String(describing: SpinnerCell.self), for: originalIndexPath)
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if sectionViewItems.isEmpty {
            if let cell = cell as? PlaceholderCell {
                cell.set(backgroundStyle: .transparent, isFirst: true)
                cell.icon = UIImage(named: "outgoing_raw_48")
                cell.text = "transactions.empty_text".localized
            }
        } else if indexPath.section < sectionViewItems.count {
            let viewItems = sectionViewItems[indexPath.section].viewItems
            let viewItem = viewItems[indexPath.row]

            if let cell = cell as? BaseThemeCell {
                cell.set(backgroundStyle: .bordered, isFirst: indexPath.row == 0, isLast: indexPath.row == viewItems.count - 1)
                cell.bind(rootElement: rootElement(viewItem: viewItem))
            }

            viewModel.onDisplay(sectionIndex: indexPath.section, index: indexPath.row)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let originalIndexPath = delegate?.originalIndexPath(tableView: tableView, dataSource: self, indexPath: indexPath) ?? indexPath

        if indexPath.section < sectionViewItems.count {
            tableView.deselectRow(at: originalIndexPath, animated: true)
            itemClicked(item: sectionViewItems[indexPath.section].viewItems[indexPath.row])
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if sectionViewItems.isEmpty {
            let contentHeight = delegate?.height(tableView: tableView, except: self) ?? 0
            return max(0, tableView.height - tableView.safeAreaInsets.height - contentHeight)
        } else if indexPath.section < sectionViewItems.count {
            return .heightDoubleLineCell
        } else {
            return .margin32
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        section < sectionViewItems.count ? .heightSingleLineCell : 0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section < sectionViewItems.count {
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: TransactionDateHeaderView.self))
        } else {
            return nil
        }
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let view = view as? TransactionDateHeaderView else {
            return
        }

        view.text = sectionViewItems[section].title
    }

}
