import UIKit
import ActionSheet
import ThemeKit
import SectionsTableView

class UnlinkViewController: ThemeActionSheetController {
    private let delegate: IUnlinkViewDelegate

    private let titleView = BottomSheetTitleView()
    private let tableView = SelfSizedSectionsTableView(style: .grouped)
    private let deleteButton = ThemeButton()

    private var viewItems = [UnlinkModule.ViewItem]()

    init(delegate: IUnlinkViewDelegate) {
        self.delegate = delegate
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

        titleView.onTapClose = { [weak self] in
            self?.delegate.onTapClose()
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(titleView.snp.bottom)
        }

        tableView.registerCell(forClass: CheckboxCell.self)
        tableView.sectionDataSource = self

        view.addSubview(deleteButton)
        deleteButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(tableView.snp.bottom).offset(CGFloat.margin6x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin4x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        deleteButton.apply(style: .primaryRed)
        deleteButton.setTitle("security_settings.delete_alert_button".localized, for: .normal)
        deleteButton.addTarget(self, action: #selector(_onTapDelete), for: .touchUpInside)

        delegate.onLoad()

        tableView.reload()
    }

    @objc private func _onTapDelete() {
        delegate.onTapDelete()
    }

    private func checkboxRow(viewItem: UnlinkModule.ViewItem, index: Int) -> RowProtocol {
        let checkboxText = text(itemType: viewItem.type)

        return Row<CheckboxCell>(
                id: "checkbox_\(index)",
                hash: "\(viewItem.checked)",
                dynamicHeight: { width in
                    CheckboxCell.height(containerWidth: width, text: checkboxText)
                },
                bind: { cell, _ in
                    cell.bind(
                            text: checkboxText,
                            checked: viewItem.checked
                    )
                },
                action: { [weak self] _ in
                    self?.delegate.onTapViewItem(index: index)
                }
        )
    }

    private func text(itemType: UnlinkModule.ItemType) -> String {
        switch itemType {
        case .deleteAccount(let accountTypeTitle):
            return "settings_manage_keys.delete.confirmation_remove".localized(accountTypeTitle)
        case .disableCoins(let coinCodes):
            return "settings_manage_keys.delete.confirmation_disable".localized(coinCodes)
        case .loseAccess:
            return "settings_manage_keys.delete.confirmation_loose".localized
        }
    }

}

extension UnlinkViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "main",
                    rows: viewItems.enumerated().map {
                        checkboxRow(viewItem: $1, index: $0)
                    }
            )
        ]
    }

}

extension UnlinkViewController: IUnlinkView {

    func set(accountTypeTitle: String) {
        titleView.bind(
                title: "settings_manage_keys.delete.title".localized,
                subtitle: accountTypeTitle,
                image: UIImage(named: "warning_2_24")?.tinted(with: .themeLucian)
        )
    }

    func set(viewItems: [UnlinkModule.ViewItem]) {
        self.viewItems = viewItems
        tableView.reload()
    }

    func set(deleteButtonEnabled: Bool) {
        deleteButton.isEnabled = deleteButtonEnabled
    }

    func showSuccess() {
        HudHelper.instance.showSuccess()
    }

}
