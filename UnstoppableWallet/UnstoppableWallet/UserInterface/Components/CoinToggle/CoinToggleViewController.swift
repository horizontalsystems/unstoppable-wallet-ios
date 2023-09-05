import Combine
import UIKit
import Alamofire
import RxSwift
import RxCocoa
import SnapKit
import ComponentKit
import MarketKit
import SectionsTableView
import ThemeKit

class CoinToggleViewController: ThemeSearchViewController {
    private let viewModel: ICoinToggleViewModel
    private var cancellables = Set<AnyCancellable>()
    let disposeBag = DisposeBag()

    let tableView = SectionsTableView(style: .grouped)

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
        $filter
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.viewModel.onUpdate(filter: $0 ?? "") }
                .store(in: &cancellables)

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

    private func elements(viewItem: CoinToggleViewModel.ViewItem, forceToggleOn: Bool? = nil) -> [CellBuilderNew.CellElement] {
        var elements = [CellBuilderNew.CellElement]()

        elements.append(.image32 { (component: ImageComponent) -> () in
            component.setImage(urlString: viewItem.imageUrl, placeholder: viewItem.placeholderImageName.flatMap { UIImage(named: $0) })
        })
        elements.append(.vStackCentered([
            .hStack([
                .text { component in
                    component.font = .body
                    component.textColor = .themeLeah
                    component.text = viewItem.title
                    component.setContentHuggingPriority(.required, for: .horizontal)
                },
                .margin8,
                .badge { component in
                    component.badgeView.set(style: .small)
                    component.badgeView.text = viewItem.badge
                    component.isHidden = viewItem.badge == nil
                },
                .margin0,
                .text { _ in }
            ]),
            .margin(1),
            .text { (component: TextComponent) -> () in
                component.font = .subhead2
                component.textColor = .themeGray
                component.text = viewItem.subtitle
            }
        ]))
        switch viewItem.state {
        case let .toggleVisible(enabled, hasSettings, hasInfo):
            elements.append(contentsOf: [
                .secondaryCircleButton { [weak self] component in
                    component.isHidden = !hasSettings
                    component.button.set(image: UIImage(named: "edit2_20"), style: .transparent)
                    component.onTap = {
                        self?.viewModel.onTapSettings(uid: viewItem.uid)
                    }
                },
                .secondaryCircleButton { [weak self] component in
                    component.isHidden = !hasInfo
                    component.button.set(image: UIImage(named: "circle_information_20"), style: .transparent)
                    component.onTap = {
                        self?.viewModel.onTapInfo(uid: viewItem.uid)
                    }
                },
                .switch { (component: SwitchComponent) -> () in
                    if let forceOn = forceToggleOn {
                        component.switchView.setOn(forceOn, animated: true)
                    } else {
                        component.switchView.isOn = enabled
                    }

                    component.onSwitch = { [weak self] enabled in
                        self?.onToggle(viewItem: viewItem, enabled: enabled)
                    }
                }
            ])
        default: ()
        }

        return elements
    }

    private func row(viewItem: CoinToggleViewModel.ViewItem, isLast: Bool) -> RowProtocol {
        let elements = elements(viewItem: viewItem)
        var hash: String = ""
        var action: (() -> ())?

        switch viewItem.state {
        case let .toggleVisible(enabled, hasSettings, hasInfo):
            hash = "coin_\(enabled)_\(hasSettings)_\(hasInfo)_\(isLast)"
        case .toggleHidden(let notSupportedReason):
            hash = "coin_\(isLast)"
            action = { [weak self] in
                self?.onTapToggleHidden(viewItem: viewItem, notSupportedReason: notSupportedReason)
            }
        }
        return CellBuilderNew.row(
                rootElement: .hStack(elements),
                tableView: tableView,
                id: "coin_\(viewItem.uid)",
                hash: hash,
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: .transparent, isLast: isLast)
                },
                action: action
        )
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

        CellBuilderNew.buildStatic(cell: cell, rootElement: .hStack(elements(viewItem: viewItems[index], forceToggleOn: on)))
    }

    func onTapToggleHidden(viewItem: CoinToggleViewModel.ViewItem, notSupportedReason: String) {
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
