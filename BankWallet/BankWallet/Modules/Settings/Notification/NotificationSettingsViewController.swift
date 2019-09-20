import UIKit
import SectionsTableView

class NotificationSettingsViewController: WalletViewController {
    private let delegate: INotificationSettingsViewDelegate

    private var viewItems = [PriceAlertViewItem]()
    private let tableView = SectionsTableView(style: .grouped)

    init(delegate: INotificationSettingsViewDelegate) {
        self.delegate = delegate

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings_notifications.title".localized

        tableView.registerCell(forClass: ImageSingleLineValueCell.self)
        tableView.registerHeaderFooter(forClass: DescriptionView.self)
        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        delegate.viewDidLoad()
        tableView.buildSections()
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

}

extension NotificationSettingsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let descriptionText = "settings_notifications.description".localized

        let headerState: ViewState<DescriptionView> = .cellType(hash: "top_description", binder: { view in
            view.bind(text: descriptionText)
        }, dynamicHeight: { [unowned self] _ in
            DescriptionView.height(containerWidth: self.tableView.bounds.width, text: descriptionText)
        })

        return [
            Section(
                    id: "alerts",
                    headerState: headerState,
                    footerState: .margin(height: .margin8x),
                    rows: viewItems.enumerated().map { (index, item) in
                        Row<ImageSingleLineValueCell>(
                                id: item.code,
                                hash: "\(item.state)",
                                height: CGFloat.heightSingleLineCell,
                                bind: { [unowned self] cell, _ in
                                    cell.bind(
                                            image: UIImage(named: "\(item.code.lowercased())")?.tinted(with: .appGray),
                                            title: item.title,
                                            value: "\(item.state)",
                                            last: index == self.viewItems.count - 1
                                    )
                                },
                                action: { [weak self] _ in
                                    self?.showSelector(index: index)
                                }
                        )
                    }
            )
        ]
    }

    private func showSelector(index: Int) {
        let controller = NotificationSettingsSelectorViewController(selectedState: viewItems[index].state, onSelect: { [weak self] state in
            self?.delegate.didSelect(state: state, index: index)
        })

        controller.title = self.viewItems[index].title

        navigationController?.pushViewController(controller, animated: true)
    }

}

extension NotificationSettingsViewController: INotificationSettingsView {

    func set(viewItems: [PriceAlertViewItem]) {
        self.viewItems = viewItems
        tableView.reload(animated: true)
    }

}
