import UIKit
import SectionsTableView
import SnapKit
import ThemeKit
import RxSwift
import RxCocoa
import MarketKit
import ComponentKit
import Alamofire

class CoinToggleViewController: ThemeSearchViewController {
    private let viewModel: ICoinToggleViewModel
    let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private var viewItems: [CoinToggleViewModel.ViewItem] = []
    private var isLoaded = false

    init(viewModel: ICoinToggleViewModel) {
        self.viewModel = viewModel

        super.init(scrollViews: [tableView])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.onUpdate(viewItems: $0) }

        tableView.buildSections()

        isLoaded = true
    }

    private func onUpdate(viewItems: [CoinToggleViewModel.ViewItem]) {
        let animated = self.viewItems.map { $0.uid } == viewItems.map { $0.uid }
        self.viewItems = viewItems

        if isLoaded {
            tableView.reload(animated: animated)
        }
    }

    private func bind(cell: BaseThemeCell, viewItem: CoinToggleViewModel.ViewItem, isLast: Bool) {
        cell.set(backgroundStyle: .claude, isLast: isLast)

        cell.bind(index: 0, block: { (component: ImageComponent) in
            component.setImage(urlString: viewItem.imageUrl, placeholder: viewItem.placeholderImageName.flatMap { UIImage(named: $0) })
        })

        cell.bind(index: 1, block: { (component: MultiTextComponent) in
            if let badge = viewItem.blockchainBadge {
                component.set(style: .m7)
                component.titleBadge.text = badge
            } else {
                component.set(style: .m1)
            }
            component.title.set(style: .b2)
            component.subtitle.set(style: .d1)

            component.title.text = viewItem.title
            component.subtitle.text = viewItem.subtitle
        })
    }

    private func row(viewItem: CoinToggleViewModel.ViewItem, isLast: Bool) -> RowProtocol {
        switch viewItem.state {
        case let .toggleVisible(enabled, hasSettings):
            return CellBuilder.row(
                    elements: [.image24, .multiText, hasSettings ? .margin4 : .margin16, .transparentIconButton, .margin4, .switch],
                    tableView: tableView,
                    id: "coin_\(viewItem.uid)",
                    hash: "coin_\(enabled)_\(hasSettings)_\(isLast)",
                    height: .heightDoubleLineCell,
                    bind: { [weak self] cell in
                        self?.bind(cell: cell, viewItem: viewItem, isLast: isLast)

                        cell.bind(index: 2, block: { (component: TransparentIconButtonComponent) in
                            component.isHidden = !hasSettings
                            component.button.set(image: UIImage(named: "edit_20"))
                            component.onTap = { [weak self] in
                                self?.viewModel.onTapSettings(uid: viewItem.uid)
                            }
                        })

                        cell.bind(index: 3) { (component: SwitchComponent) in
                            component.switchView.isOn = enabled
                            component.onSwitch = { [weak self] enabled in
                                self?.onToggle(viewItem: viewItem, enabled: enabled)
                            }
                        }
                    }
            )
        case .toggleHidden:
            return CellBuilder.selectableRow(
                    elements: [.image24, .multiText],
                    tableView: tableView,
                    id: "coin_\(viewItem.uid)",
                    hash: "coin_\(isLast)",
                    height: .heightDoubleLineCell,
                    autoDeselect: true,
                    bind: { [weak self] cell in
                        self?.bind(cell: cell, viewItem: viewItem, isLast: isLast)
                    },
                    action: {
                        print("On click \(viewItem.uid)")
                    }
            )
        }
    }

    override func onUpdate(filter: String?) {
        viewModel.onUpdate(filter: filter ?? "")
    }

    private func onToggle(viewItem: CoinToggleViewModel.ViewItem, enabled: Bool) {
        if enabled {
            viewModel.onEnable(uid: viewItem.uid)
        } else {
            viewModel.onDisable(uid: viewItem.uid)
        }
    }

    func setToggle(on: Bool, uid: String) {
        guard let index = viewItems.firstIndex(where: { $0.uid == uid }) else {
            return
        }

        guard let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? BaseThemeCell else {
            return
        }

        cell.bind(index: 3) { (component: SwitchComponent) in
            component.switchView.setOn(on, animated: true)
        }
    }

}

extension CoinToggleViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "coins",
                    headerState: .margin(height: .margin4),
                    footerState: .margin(height: .margin32),
                    rows: viewItems.enumerated().map { index, viewItem in
                        row(viewItem: viewItem, isLast: index == viewItems.count - 1)
                    }
            )
        ]
    }

}
