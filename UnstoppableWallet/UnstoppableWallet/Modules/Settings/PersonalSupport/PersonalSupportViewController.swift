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
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings.personal_support".localized

        telegramUsernameCell.inputPlaceholder = "settings.personal_support.telegram_username.placeholder".localized
        telegramUsernameCell.onChangeText = { [weak self] in self?.viewModel.onChanged(username: $0) }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.sectionDataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        view.addSubview(buttonsHolder)
        buttonsHolder.snp.makeConstraints { make in
            make.height.equalTo(.margin16 + .heightButton + .margin32).priority(.high)
            make.leading.trailing.bottom.equalToSuperview()
        }

        let stackView = UIStackView()
        buttonsHolder.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(CGFloat.margin24)
        }

        stackView.axis = .vertical
        stackView.spacing = .margin16

        stackView.addArrangedSubview(requestButton)
        requestButton.set(style: .yellow)
        requestButton.setTitle("settings.personal_support.request".localized, for: .normal)
        requestButton.addTarget(self, action: #selector(onTapRequest), for: .touchUpInside)

        stackView.addArrangedSubview(requestingButton)
        requestingButton.set(style: .gray, accessoryType: .spinner)
        requestingButton.isEnabled = false
        requestingButton.setTitle("settings.personal_support.request".localized, for: .normal)

        viewModel.$requestButtonState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.sync(buttonState: $0) }
            .store(in: &cancellables)

        viewModel.successPublisher
            .receive(on: DispatchQueue.main)
            .sink { _ in HudHelper.instance.showSuccessBanner(title: "alert.success_action".localized) }
            .store(in: &cancellables)

        viewModel.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { text in HudHelper.instance.showErrorBanner(title: text) }
            .store(in: &cancellables)

        sync(buttonState: viewModel.requestButtonState)

        tableView.buildSections()
    }

    private func sync(buttonState: AsyncActionButtonState) {
        switch buttonState {
        case .enabled:
            requestButton.isEnabled = true
            requestButton.isHidden = false
            requestingButton.isHidden = true
        case .spinner:
            requestButton.isHidden = true
            requestingButton.isHidden = false
        case .disabled:
            requestButton.isEnabled = false
            requestButton.isHidden = false
            requestingButton.isHidden = true
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
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
