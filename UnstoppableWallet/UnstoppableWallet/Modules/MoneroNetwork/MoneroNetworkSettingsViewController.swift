import MarketKit
import MessageUI
import SectionsTableView
import SnapKit
import UIKit

class MoneroNetworkSettingsViewController: ThemeActionSheetController {
    private let viewModel: MoneroNetworkSettingsViewModel

    private let titleView = BottomSheetTitleView()
    private let tableView = SelfSizedSectionsTableView(style: .grouped)
    private let doneButton = PrimaryButton()

    init(viewModel: MoneroNetworkSettingsViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }
        titleView.bind(
            image: .local(name: "settings_2_24", tint: .warning),
            title: "monero_network.settings.title".localized,
            viewController: self
        )

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(titleView.snp.bottom)
        }

        tableView.sectionDataSource = self

        view.addSubview(doneButton)
        doneButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalTo(tableView.snp.bottom).offset(CGFloat.margin24)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin24)
        }

        doneButton.set(style: .yellow)
        doneButton.setTitle("button.done".localized, for: .normal)
        doneButton.addTarget(self, action: #selector(onTapDone), for: .touchUpInside)

        tableView.buildSections()
    }

    @objc private func onTapDone() {
        viewModel.onTapSettingsDone()
        dismiss(animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        viewModel.setCurrent()
    }
}

extension MoneroNetworkSettingsViewController: SectionsDataSource {
    func buildSections() -> [SectionProtocol] {
        [
            Section(
                id: "main",
                rows: [
                    tableView.descriptionRow(id: "description", text: "monero_network.settings.description".localized),
                    SelectorModule.row(
                        viewItem: SelectorModule.ViewItem(title: "monero_network.settings.trust".localized, subtitle: viewModel.nodeLabel, selected: viewModel.isTrusted),
                        tableView: tableView,
                        isOn: viewModel.isTrusted,
                        backgroundStyle: .bordered,
                        index: 0,
                        isFirst: true,
                        isLast: true
                    ) { [weak self] _, isOn in
                        self?.viewModel.onToggleIsTrusted(isOn: isOn)
                    },
                ]
            ),
        ]
    }
}
