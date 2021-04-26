import UIKit
import SectionsTableView
import ThemeKit
import ComponentKit

class ChartNotificationViewController: ThemeViewController {
    private let delegate: IChartNotificationViewDelegate

    private let titleView = BottomSheetTitleView()
    private let spacer = UIView()

    private let tableView = SelfSizedSectionsTableView(style: .grouped)
    private let warningView = UIView()

    private var titleViewModel: PriceAlertTitleViewModel?
    private var sectionViewModels: [PriceAlertSectionViewModel]?

    init(delegate: IChartNotificationViewDelegate) {
        self.delegate = delegate

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

        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }
        titleView.backgroundColor = .themeLawrence

        view.addSubview(spacer)
        spacer.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(titleView.snp.bottom)
            maker.height.equalTo(CGFloat.margin3x)
        }

        spacer.backgroundColor = .themeLawrence

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.top.equalTo(spacer.snp.bottom)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        tableView.registerCell(forClass: B4Cell.self)
        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)
        tableView.sectionDataSource = self

        tableView.backgroundColor = .themeLawrence
        tableView.separatorStyle = .none

        warningView.isHidden = true

        view.addSubview(warningView)
        warningView.snp.makeConstraints { maker in
            maker.top.equalTo(spacer.snp.bottom)
            maker.bottom.leading.trailing.equalToSuperview()
        }

        warningView.backgroundColor = .themeLawrence

        let warningLabel = UILabel()
        warningView.addSubview(warningLabel)
        warningLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
        }

        warningLabel.numberOfLines = 0
        warningLabel.font = .subhead2
        warningLabel.textColor = .themeGray
        warningLabel.text = "settings.notifications.disabled_text".localized

        let settingsButton = ThemeButton().apply(style: .secondaryDefault)
        warningView.addSubview(settingsButton)
        settingsButton.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(warningLabel.snp.bottom).offset(CGFloat.margin8x)
        }

        settingsButton.setTitle("settings.notifications.settings_button".localized, for: .normal)
        settingsButton.addTarget(self, action: #selector(onTapSettingsButton), for: .touchUpInside)

        delegate.viewDidLoad()
        tableView.reload()
    }

    @objc func onTapSettingsButton() {
        delegate.didTapSettingsButton()
    }

}

extension ChartNotificationViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let sectionsCount = sectionViewModels?.count ?? 0

        return sectionViewModels?.enumerated().compactMap { [weak self] index, section in
            self?.section(sectionModel: section, sectionIndex: index, last: index == sectionsCount - 1)
        } ?? []
    }

    func section(sectionModel: PriceAlertSectionViewModel, sectionIndex: Int, last: Bool) -> SectionProtocol {
        var headerState: ViewState<SubtitleHeaderFooterView>?

        if let header = sectionModel.header {
            headerState = .cellType(hash: "header_\(sectionIndex)", binder: { view in
                view.bind(text: header.localized)
                view.contentView.backgroundColor = .themeLawrence
            }, dynamicHeight: { containerWidth in
                SubtitleHeaderFooterView.height
            })
        }

        return Section(
                id: "section_\(sectionIndex)",
                headerState: headerState ?? .margin(height: 0),
                footerState: .margin(height: last ? 32 : 20),
                rows: sectionModel.rows.enumerated().compactMap { [weak self] index, row in
                    self?.row(rowModel: row, sectionIndex: sectionIndex, rowIndex: index, last: index == sectionModel.rows.count - 1)
                }
        )
    }

    func row(rowModel: PriceAlertSectionViewModel.Row, sectionIndex: Int, rowIndex: Int, last: Bool) -> RowProtocol {
        Row<B4Cell>(
                id: "row_\(rowIndex)",
                hash: "\(rowModel.selected)",
                height: .heightCell48,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .transparent, isLast: last)
                    cell.title = rowModel.title
                    cell.valueImageTintColor = .themeJacob
                    cell.valueImage = rowModel.selected ? UIImage(named: "check_1_20")?.withRenderingMode(.alwaysTemplate) : nil
                },
                action: { _ in
                    rowModel.action(rowIndex)
                }
        )
    }

}

extension ChartNotificationViewController: IChartNotificationView {

    func set(spacerMode: NotificationSettingPresentMode) {
        spacer.snp.updateConstraints { maker in
            maker.height.equalTo(spacerMode == .all ? CGFloat.margin3x : 0)
        }
    }

    func set(titleViewModel: PriceAlertTitleViewModel) {
        titleView.bind(
                title: titleViewModel.title.localized,
                subtitle: titleViewModel.subtitle,
                image: UIImage(named: "bell_24"),
                tintColor: .themeJacob
        )
    }

    func set(sectionViewModels: [PriceAlertSectionViewModel]) {
        self.sectionViewModels = sectionViewModels

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

    func showError(error: Error) {
        HudHelper.instance.showError(title: error.smartDescription)
    }

}
