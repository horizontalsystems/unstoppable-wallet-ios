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

        titleView.bind(
                title: "switch_account.title".localized,
                subtitle: "switch_account.subtitle".localized,
                image: UIImage(named: "switch_wallet_24"),
                tintColor: .themeGray
        )
        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(titleView.snp.bottom)
            maker.bottom.equalToSuperview()
        }

        tableView.contentInsetAdjustmentBehavior = .never
        tableView.automaticallyAdjustsScrollIndicatorInsets = false
        tableView.sectionDataSource = self

        tableView.buildSections()

        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in self?.dismiss(animated: true) }
    }

}

extension SwitchAccountViewController: SectionsDataSource {

    private func row(viewItem: SwitchAccountViewModel.ViewItem, index: Int, isFirst: Bool, isLast: Bool) -> RowProtocol {
        CellBuilder.selectableRow(
                elements: [.image24, .multiText, .image20],
                tableView: tableView,
                id: "item_\(index)",
                height: .heightDoubleLineCell,
                bind: { cell in
                    cell.set(backgroundStyle: .transparent, isFirst: isFirst, isLast: isLast)

                    cell.bind(index: 0, block: { (component: ImageComponent) in
                        component.imageView.image = viewItem.selected ? UIImage(named: "circle_radioon_24")?.withTintColor(.themeJacob) : UIImage(named: "circle_radiooff_24")?.withTintColor(.themeGray)
                    })
                    cell.bind(index: 1, block: { (component: MultiTextComponent) in
                        component.set(style: .m1)
                        component.title.set(style: .b2)
                        component.subtitle.set(style: .d1)

                        component.title.text = viewItem.title
                        component.subtitle.text = viewItem.subtitle
                        component.subtitle.lineBreakMode = .byTruncatingMiddle
                    })

                    cell.bind(index: 2, block: { (component: ImageComponent) in
                        component.isHidden = !viewItem.watchAccount
                        component.imageView.image = UIImage(named: "eye_20")?.withTintColor(.themeGray)
                    })
                },
                action: { [weak self] in
                    self?.viewModel.onSelect(accountId: viewItem.accountId)
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "main",
                    footerState: .margin(height: .margin16),
                    rows: viewModel.viewItems.enumerated().map { index, viewItem in
                        row(viewItem: viewItem, index: index, isFirst: index == 0, isLast: index == viewModel.viewItems.count - 1)
                    }
            )
        ]
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
