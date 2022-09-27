import UIKit
import ThemeKit
import SectionsTableView
import SnapKit
import RxSwift
import RxCocoa
import ComponentKit
import ActionSheet

class SwitchAccountViewController: ThemeActionSheetController {
    private let viewModel: SwitchAccountViewModel
    private let disposeBag = DisposeBag()

    private let titleView = BottomSheetTitleView()
    private let tableView = SelfSizedSectionsTableView(style: .grouped)

    init(viewModel: SwitchAccountViewModel) {
        self.viewModel = viewModel
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

        titleView.title = "switch_account.title".localized
        titleView.image = UIImage(named: "switch_wallet_24")?.withTintColor(.themeJacob)
        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(titleView.snp.bottom)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin24)
        }

        tableView.contentInsetAdjustmentBehavior = .never
        tableView.automaticallyAdjustsScrollIndicatorInsets = false

        tableView.sectionDataSource = self

        tableView.buildSections()

        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in self?.dismiss(animated: true) }
    }

}

extension SwitchAccountViewController: SectionsDataSource {

    private func row(viewItem: SwitchAccountViewModel.ViewItem, watchIcon: Bool, index: Int, isFirst: Bool, isLast: Bool) -> RowProtocol {
        CellBuilderNew.row(
                rootElement: .hStack([
                    .image24 { component in
                        component.imageView.image = viewItem.selected ? UIImage(named: "circle_radioon_24")?.withTintColor(.themeJacob) : UIImage(named: "circle_radiooff_24")?.withTintColor(.themeGray)
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
                            component.text = viewItem.subtitle
                        }
                    ]),
                    .image20 { component in
                        component.isHidden = !watchIcon
                        component.imageView.image = UIImage(named: "binocule_20")?.withTintColor(.themeGray)
                    }
                ]),
                tableView: tableView,
                id: "item_\(index)",
                height: .heightDoubleLineCell,
                bind: { cell in
                    cell.set(backgroundStyle: .bordered, isFirst: isFirst, isLast: isLast)
                },
                action: { [weak self] in
                    self?.viewModel.onSelect(accountId: viewItem.accountId)
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        if !viewModel.regularViewItems.isEmpty {
            let section = Section(
                    id: "regular",
                    headerState: tableView.sectionHeader(text: "switch_account.wallets".localized),
                    footerState: .margin(height: viewModel.watchViewItems.isEmpty ? 0 : .margin24),
                    rows: viewModel.regularViewItems.enumerated().map { index, viewItem in
                        row(viewItem: viewItem, watchIcon: false, index: index, isFirst: index == 0, isLast: index == viewModel.regularViewItems.count - 1)
                    }
            )

            sections.append(section)
        }

        if !viewModel.watchViewItems.isEmpty {
            let section = Section(
                    id: "watch",
                    headerState: tableView.sectionHeader(text: "switch_account.watch_addresses".localized),
                    rows: viewModel.watchViewItems.enumerated().map { index, viewItem in
                        row(viewItem: viewItem, watchIcon: true, index: index, isFirst: index == 0, isLast: index == viewModel.watchViewItems.count - 1)
                    }
            )

            sections.append(section)
        }

        return sections
    }

}

extension SwitchAccountViewController: ActionSheetViewDelegate {

    public var height: CGFloat? {
        guard let window = view.window else {
            return nil
        }

        let availableHeight = window.bounds.height - BottomSheetTitleView.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom - 100
        return tableView.intrinsicContentSize.height > availableHeight ? availableHeight : nil
    }

}
