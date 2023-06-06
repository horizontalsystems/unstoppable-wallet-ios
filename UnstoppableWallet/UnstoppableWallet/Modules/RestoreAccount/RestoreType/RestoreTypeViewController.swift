import Combine
import UIKit
import ThemeKit
import SnapKit
import SectionsTableView
import ComponentKit

class RestoreTypeViewController: ThemeViewController {
    private let viewModel: RestoreTypeViewModel
    private var cancellables = Set<AnyCancellable>()

    private let tableView = SectionsTableView(style: .grouped)
    private weak var returnViewController: UIViewController?

    init(viewModel: RestoreTypeViewModel, returnViewController: UIViewController?) {
        self.viewModel = viewModel
        self.returnViewController = returnViewController

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "restore.title".localized

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(didTapCancel))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.sectionDataSource = self

        viewModel.showModulePublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.show(type: $0)
                }
                .store(in: &cancellables)

        viewModel.showCloudNotAvailablePublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.showNotCloudAvailable()
                }
                .store(in: &cancellables)

        tableView.buildSections()
    }

    @objc private func didTapCancel() {
        dismiss(animated: true)
    }

    private func row(_ item: RestoreTypeViewModel.RestoreType) -> RowProtocol {
        let backgroundStyle: BaseThemeCell.BackgroundStyle = .lawrence
        let titleFont: UIFont = .headline2
        let valueFont: UIFont = .subhead2

        return CellBuilderNew.row(
                rootElement: .hStack([
                    .image24 { (component: ImageComponent) -> () in
                        component.imageView.image = UIImage(named: item.icon)
                    },
                    .vStackCentered([
                        .text { (component: TextComponent) -> () in
                            component.font = titleFont
                            component.textColor = .themeLeah
                            component.text = item.title
                            component.numberOfLines = 0
                        },
                        .margin4,
                        .text { (component: TextComponent) -> () in
                            component.font = valueFont
                            component.textColor = .themeGray
                            component.text = item.description
                            component.numberOfLines = 0
                        }
                    ])
                ]),
                tableView: tableView,
                id: item.description,
                autoDeselect: true,
                dynamicHeight: { containerWidth in
                    let size = CellBuilderNew.height(
                            containerWidth: containerWidth,
                            backgroundStyle: backgroundStyle,
                            text: item.title,
                            font: titleFont,
                            verticalPadding: .margin24,
                            elements: [.fixed(width: .iconSize24), .multiline]
                    ) + .margin4 +
                    CellBuilderNew.height(
                            containerWidth: containerWidth,
                            backgroundStyle: backgroundStyle,
                            text: item.description,
                            font: valueFont,
                            verticalPadding: 0,
                            elements: [.fixed(width: .iconSize24), .multiline]
                    )

                    return max(106, size)   // usually cells will have 3 lines
                },
                bind: { cell in
                    cell.set(backgroundStyle: backgroundStyle, isFirst: true, isLast: true)
                },
                action: { [weak self] in
                    self?.viewModel.onTap(type: item)
                }
        )
    }

    private func show(type: RestoreTypeViewModel.RestoreType) {
        switch type {
        case .cloudRestore:
            let viewController = RestoreCloudModule.viewController(returnViewController: returnViewController)
            navigationController?.pushViewController(viewController, animated: true)
        case .recoveryOrPrivateKey:
            let viewController = RestoreModule.viewController(sourceViewController: self, returnViewController: returnViewController)
            navigationController?.pushViewController(viewController, animated: true)
        }
    }

    private func showNotCloudAvailable() {
        let viewController = BottomSheetModule.cloudNotAvailableController()
        present(viewController, animated: true)
    }

}

extension RestoreTypeViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        viewModel.items.enumerated().map { index, item in
            Section(
                    id: "restore_type",
                    headerState: index == 0 ? .margin(height: .margin12) : .margin(height: 0),
                    footerState: index == viewModel.items.count - 1 ? .margin(height: .margin32) : .margin(height: .margin12),
                    rows: [row(item)])
        }
    }

}
