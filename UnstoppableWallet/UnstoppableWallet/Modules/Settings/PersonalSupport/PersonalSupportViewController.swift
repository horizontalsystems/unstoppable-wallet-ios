import UIKit
import SectionsTableView
import ThemeKit
import ComponentKit
import Combine

class PersonalSupportViewController: KeyboardAwareViewController {
    private let viewModel: PersonalSupportViewModel
    private var cancellables = Set<AnyCancellable>()

    private let tableView = SectionsTableView(style: .grouped)
    private let telegramUsernameCell = InputCell()

    private let buttonsHolder = BottomGradientHolder()
    private let requestButton = PrimaryButton()
    private let requestingButton = PrimaryButton()

    init(viewModel: PersonalSupportViewModel) {
        self.viewModel = viewModel

        super.init(scrollViews: [tableView], accessoryView: buttonsHolder)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings.personal_support".localized

        telegramUsernameCell.inputPlaceholder = "settings.personal_support.telegram_username.placeholder".localized
        telegramUsernameCell.onChangeText = { [weak self] in self?.viewModel.onChanged(username: $0) }
        telegramUsernameCell.autocapitalizationType = .none

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.sectionDataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        buttonsHolder.add(to: self)
        buttonsHolder.addSubview(requestButton)

        requestButton.set(style: .yellow)
        requestButton.setTitle("settings.personal_support.request".localized, for: .normal)
        requestButton.addTarget(self, action: #selector(onTapRequest), for: .touchUpInside)

        buttonsHolder.addSubview(requestingButton)

        requestingButton.set(style: .gray, accessoryType: .spinner)
        requestingButton.isEnabled = false
        requestingButton.setTitle("settings.personal_support.request".localized, for: .normal)

        viewModel.hiddenRequestButtonPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.requestButton.isHidden = $0 }
            .store(in: &cancellables)

        viewModel.enabledRequestButtonPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.requestButton.isEnabled = $0 }
            .store(in: &cancellables)

        viewModel.hiddenRequestingButtonPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.requestingButton.isHidden = $0 }
            .store(in: &cancellables)

        viewModel.successPublisher
            .receive(on: DispatchQueue.main)
            .sink { _ in HudHelper.instance.showSuccessBanner(title: "alert.success_action".localized) }
            .store(in: &cancellables)

        viewModel.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { text in HudHelper.instance.showErrorBanner(title: text) }
            .store(in: &cancellables)

        tableView.buildSections()
    }

    @objc private func onTapRequest() {
        viewModel.onTapRequest()
    }

}

extension PersonalSupportViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                id: "personal-support",
                headerState: tableView.sectionHeader(text: "settings.personal_support.telegram_username.title".localized),
                footerState: tableView.sectionFooter(text: "settings.personal_support.description".localized),
                rows: [
                    StaticRow(
                        cell: telegramUsernameCell,
                        id: "telegram-username"
                    )
                ]
            ),
        ]
    }

}
