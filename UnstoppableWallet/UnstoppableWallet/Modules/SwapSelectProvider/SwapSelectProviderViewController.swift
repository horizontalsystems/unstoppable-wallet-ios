import UIKit
import SectionsTableView
import ThemeKit
import RxSwift
import ComponentKit

class SwapSelectProviderViewController: ThemeActionSheetController {
    private let viewModel: SwapSelectProviderViewModel
    private let disposeBag = DisposeBag()

    private let titleView = BottomSheetTitleView()
    private let tableView = SelfSizedSectionsTableView(style: .grouped)
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

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.title = "swap.switch_provider.title".localized
        titleView.image = UIImage(named: "arrow_swap_2_24")?.withTintColor(.themeJacob)
        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.top.equalTo(titleView.snp.bottom)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin24)
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.sectionDataSource = self

        subscribe(disposeBag, viewModel.sectionViewItemsDriver) { [weak self] viewItems in
            self?.viewItems = viewItems

            self?.reloadTable()
        }

        subscribe(disposeBag, viewModel.selectedSignal) { [weak self] in self?.navigationController?.popViewController(animated: true) }

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
        [
            Section(
                    id: "theme",
                    rows: viewItems.enumerated().map { index, viewItem in
                        tableView.imageTitleCheckRow(
                                id: viewItem.title,
                                backgroundStyle: .bordered,
                                image: viewItem.icon,
                                title: viewItem.title,
                                selected: viewItem.selected,
                                isFirst: index == 0,
                                isLast: index == viewItems.count - 1,
                                action: { [weak self] in
                                    self?.viewModel.onSelect(index: index)
                                    self?.dismiss(animated: true)
                                }
                        )
                    }
            )
        ]
    }

}
