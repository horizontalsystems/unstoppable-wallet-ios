import UIKit
import SectionsTableView
import ThemeKit

class ChartNotificationViewController: ThemeViewController {
    private let delegate: IChartNotificationViewDelegate

    private var selectedState: AlertState?

    private let titleView = BottomSheetTitleView()

    private let tableView = SelfSizedSectionsTableView(style: .grouped)
    private let warningView = UIView()

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

        let spacer = UIView()
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

        tableView.registerCell(forClass: SingleLineCheckmarkCell.self)
        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)
        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
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
        let descriptionText = "chart_alert.24h_description".localized

        let headerState: ViewState<SubtitleHeaderFooterView> = .cellType(hash: "top_description", binder: { view in
            view.bind(text: descriptionText, uppercased: false)
            view.contentView.backgroundColor = .themeLawrence
        }, dynamicHeight: { containerWidth in
            SubtitleHeaderFooterView.height
        })

        let allCases = AlertState.allCases

        return [
            Section(
                    id: "alerts",
                    headerState: headerState,
                    rows: allCases.enumerated().map { (index, state) in
                        Row<SingleLineCheckmarkCell>(
                                id: "\(state)",
                                height: CGFloat.heightSingleLineCell,
                                bind: { [unowned self] cell, _ in
                                    cell.bind(
                                            text: "\(state)",
                                            checkmarkVisible: self.selectedState == state,
                                            last: index == allCases.count - 1
                                    )
                                },
                                action: { [weak self] _ in
                                    self?.delegate.didSelect(state: state)
                                }
                        )
                    }
            )
        ]
    }

}

extension ChartNotificationViewController: IChartNotificationView {

    func set(coinName: String) {
        titleView.bind(
                title: "chart_alert.title".localized,
                subtitle: coinName,
                image: UIImage(named: "Notification Medium Icon")
        )
    }

    func set(selectedState: AlertState) {
        self.selectedState = selectedState

        tableView.reload()
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
