import UIKit
import SectionsTableView
import ThemeKit

class NotificationSettingsViewController: ThemeViewController {
    private let delegate: INotificationSettingsViewDelegate

    private var viewItems = [PriceAlertViewItem]()

    private let tableView = SectionsTableView(style: .grouped)
    private let warningView = UIView()

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

        tableView.registerCell(forClass: ImageDoubleLineValueCell.self)
        tableView.registerCell(forClass: SingleLineCell.self)
        tableView.registerHeaderFooter(forClass: TopDescriptionHeaderFooterView.self)
        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        warningView.isHidden = true

        view.addSubview(warningView)
        warningView.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(view.safeAreaLayoutGuide)
            maker.leading.trailing.equalToSuperview()
        }

        let warningLabel = UILabel()
        warningLabel.numberOfLines = 0
        warningLabel.font = .subhead2
        warningLabel.textColor = .themeGray
        warningLabel.text = "settings.notifications.disabled_text".localized

        warningView.addSubview(warningLabel)
        warningLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
        }

        let settingsButton = UIButton.appSecondary
        settingsButton.setTitle("settings.notifications.settings_button".localized, for: .normal)
        settingsButton.addTarget(self, action: #selector(onTapSettingsButton), for: .touchUpInside)

        warningView.addSubview(settingsButton)
        settingsButton.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(warningLabel.snp.bottom).offset(CGFloat.margin8x)
            maker.height.equalTo(CGFloat.heightButtonSecondary)
        }

        delegate.viewDidLoad()
        tableView.buildSections()
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    @objc func onTapSettingsButton() {
        delegate.didTapSettingsButton()
    }

}

extension NotificationSettingsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let descriptionText = "settings_notifications.description".localized

        let headerState: ViewState<TopDescriptionHeaderFooterView> = .cellType(hash: "top_description", binder: { view in
            view.bind(text: descriptionText)
        }, dynamicHeight: { [unowned self] _ in
            TopDescriptionHeaderFooterView.height(containerWidth: self.tableView.bounds.width, text: descriptionText)
        })

        return [
            Section(
                    id: "alerts",
                    headerState: headerState,
                    rows: viewItems.enumerated().map { (index, item) in
                        Row<ImageDoubleLineValueCell>(
                                id: item.code,
                                hash: "\(item.state)",
                                height: CGFloat.heightDoubleLineCell,
                                bind: { [unowned self] cell, _ in
                                    cell.bind(
                                            image: UIImage(named: "\(item.code.lowercased())")?.tinted(with: .themeGray),
                                            title: item.title,
                                            subtitle: item.code,
                                            value: "\(item.state)",
                                            valueHighlighted: item.state != .off,
                                            last: index == self.viewItems.count - 1
                                    )
                                },
                                action: { [weak self] _ in
                                    self?.showSelector(index: index)
                                }
                        )
                    }
            ),
            Section(
                    id: "deactivate",
                    headerState: .margin(height: .margin8x),
                    footerState: .margin(height: .margin8x),
                    rows: [
                        Row<SingleLineCell>(
                                id: "deactivate_all",
                                height: CGFloat.heightSingleLineCell,
                                autoDeselect: true,
                                bind: { cell, _ in
                                    cell.bind(text: "settings.notifications.deactivate_all".localized, last: true)
                                },
                                action: { [weak self] _ in
                                    self?.delegate.didTapDeactivateAll()
                                }
                        )
                    ]
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

    func showWarning() {
        warningView.isHidden = false
        tableView.isHidden = true
    }

    func hideWarning() {
        warningView.isHidden = true
        tableView.isHidden = false
    }

}
