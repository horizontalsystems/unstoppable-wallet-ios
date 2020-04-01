import UIKit
import SectionsTableView
import ThemeKit

class DerivationSettingsViewController: ThemeViewController {
    private let delegate: IDerivationSettingsViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private var viewItems = [DerivationSettingSectionViewItem]()

    init(delegate: IDerivationSettingsViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "blockchain_settings.title".localized

        tableView.registerCell(forClass: DerivationSettingCell.self)
        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)
        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        delegate.onLoad()
        tableView.buildSections()
    }

    private func handleSelect(sectionIndex: Int, rowIndex: Int) {
        delegate.onSelect(chainIndex: sectionIndex, settingIndex: rowIndex)
    }

    private func header(hash: String, text: String, additionalMargin: CGFloat = 0) -> ViewState<SubtitleHeaderFooterView> {
        .cellType(
                hash: hash,
                binder: { view in
                    view.bind(text: text)
                },
                dynamicHeight: { _ in
                    SubtitleHeaderFooterView.height + additionalMargin
                }
        )
    }

    private func section(viewItem: DerivationSettingSectionViewItem, index: Int) -> SectionProtocol {
        Section(
                id: viewItem.coinName,
                headerState: header(hash: viewItem.coinName, text: "coin_settings.derivation.title".localized(viewItem.coinName).uppercased(), additionalMargin: .margin2x),
                footerState: .margin(height: .margin8x),
                rows: viewItem.items.enumerated().map { rowIndex, rowViewItem -> RowProtocol in
                    row(viewItem: rowViewItem, enabled: viewItem.enabled, sectionIndex: index, rowIndex: rowIndex, last: rowIndex == viewItem.items.count - 1)
                }
            )
    }

    private func row(viewItem: DerivationSettingViewItem, enabled: Bool, sectionIndex: Int, rowIndex: Int, last: Bool) -> RowProtocol {
        Row<DerivationSettingCell>(
                id: viewItem.title,
                hash: "\(viewItem.selected)",
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.selectionStyle = enabled ? .default : .none
                    cell.bind(
                            title: viewItem.title,
                            subtitle: viewItem.subtitle,
                            selected: viewItem.selected,
                            enabled: enabled,
                            last: last
                    )
                },
                action: { [weak self] _ in
                    if enabled {
                        self?.handleSelect(sectionIndex: sectionIndex, rowIndex: rowIndex)
                    }
                }
        )
    }

    @objc private func onTapRightBarButton() {
        delegate.onConfirm()
    }

}

extension DerivationSettingsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        viewItems.enumerated().map { index, viewItem in
            section(viewItem: viewItem, index: index)
        }
    }

}

extension DerivationSettingsViewController: IDerivationSettingsView {

    func showNextButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.next".localized, style: .plain, target: self, action: #selector(onTapRightBarButton))
    }

    func showRestoreButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.restore".localized, style: .done, target: self, action: #selector(onTapRightBarButton))
    }

    func showDoneButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .done, target: self, action: #selector(onTapRightBarButton))
    }

    func set(viewItems: [DerivationSettingSectionViewItem]) {
        self.viewItems = viewItems
        tableView.reload(animated: true)
    }

    func showChangeAlert(chainIndex: Int, settingIndex: Int, derivationText: String) {
        let derivationText = derivationText.uppercased()
        present(BottomAlertViewController(items: [
            .title(title: "blockchain_settings.change_alert.title".localized, subtitle: derivationText, icon: UIImage(named: "Attention Icon"), iconTint: .themeJacob),
            .description(text: "blockchain_settings.change_alert.content".localized),
            .button(title: "blockchain_settings.change_alert.action_button_text".localized(derivationText), button: .appYellow, onTap: { [weak self] in
                self?.delegate.proceedChange(chainIndex: chainIndex, settingIndex: settingIndex)
            })
        ]), animated: true)
    }

}
