import Combine
import UIKit
import SnapKit
import ThemeKit
import ComponentKit
import SectionsTableView
import HUD

class RestoreCoinzixViewController: KeyboardAwareViewController {
    private let wrapperViewHeight: CGFloat = .heightButton + .margin16 + .heightButton
    private let viewModel: RestoreCoinzixViewModel
    private var cancellables = Set<AnyCancellable>()

    private weak var returnViewController: UIViewController?

    private let tableView = SectionsTableView(style: .grouped)

    private let usernameCell = TextFieldCell()
    private let passwordCell = PasswordInputCell()

    private let buttonsHolder = BottomGradientHolder()
    private let loginButton = PrimaryButton()
    private let loggingInButton = PrimaryButton()

    private var isLoaded = false

    init(viewModel: RestoreCoinzixViewModel, returnViewController: UIViewController?) {
        self.viewModel = viewModel
        self.returnViewController = returnViewController

        super.init(scrollViews: [tableView], accessoryView: buttonsHolder)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Cex.coinzix.title

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancel))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        tableView.sectionDataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        usernameCell.inputPlaceholder = "restore.coinzix.sample_username".localized
        usernameCell.keyboardType = .emailAddress
        usernameCell.autocapitalizationType = .none
        usernameCell.onChangeText = { [weak self] in self?.viewModel.onChange(username: $0 ?? "") }

        passwordCell.set(textSecure: true)
        passwordCell.onTextSecurityChange = { [weak self] in self?.passwordCell.set(textSecure: $0) }
        passwordCell.inputPlaceholder = "restore.coinzix.sample_password".localized
        passwordCell.onChangeText = { [weak self] in self?.viewModel.onChange(password: $0 ?? "") }

        view.addSubview(buttonsHolder)
        buttonsHolder.snp.makeConstraints { make in
            make.height.equalTo(wrapperViewHeight).priority(.high)
            make.leading.trailing.bottom.equalToSuperview()
        }

        let stackView = UIStackView()
        buttonsHolder.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(CGFloat.margin24)
        }

        stackView.axis = .vertical
        stackView.spacing = .margin16

        stackView.addArrangedSubview(loginButton)
        loginButton.set(style: .yellow)
        loginButton.setTitle("restore.coinzix.login".localized, for: .normal)
        loginButton.addTarget(self, action: #selector(onTapLogin), for: .touchUpInside)

        stackView.addArrangedSubview(loggingInButton)
        loggingInButton.set(style: .yellow, accessoryType: .spinner)
        loggingInButton.isEnabled = false
        loggingInButton.setTitle("restore.coinzix.login".localized, for: .normal)

        let signUpButton = PrimaryButton()
        stackView.addArrangedSubview(signUpButton)
        signUpButton.set(style: .transparent)
        signUpButton.setTitle("restore.coinzix.sign_up".localized, for: .normal)
        signUpButton.addTarget(self, action: #selector(onTapSignUp), for: .touchUpInside)

        viewModel.$loginEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in self?.loginButton.isEnabled = enabled }
            .store(in: &cancellables)

        viewModel.$loginVisible
            .receive(on: DispatchQueue.main)
            .sink { [weak self] visible in self?.loginButton.isHidden = !visible }
            .store(in: &cancellables)

        viewModel.$loggingInVisible
            .receive(on: DispatchQueue.main)
            .sink { [weak self] visible in self?.loggingInButton.isHidden = !visible }
            .store(in: &cancellables)

        viewModel.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.show(error: $0) }
            .store(in: &cancellables)

        viewModel.verifyPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mode, types in
                guard let viewController = CoinzixVerifyModule.viewController(mode: mode, twoFactorTypes: types, returnViewController: self?.returnViewController) else {
                    return
                }

                self?.navigationController?.pushViewController(viewController, animated: true)
            }
            .store(in: &cancellables)

        additionalContentInsets = UIEdgeInsets(top: 0, left: 0, bottom: -.margin16, right: 0)
        additionalInsetsOnlyForClosedKeyboard = false
        ignoreSafeAreaForAccessoryView = false

        tableView.buildSections()
        isLoaded = true
    }

    @objc private func onTapCancel() {
        (returnViewController ?? self).dismiss(animated: true)
    }

    @objc private func onTapLogin() {
        view.endEditing(true)
        viewModel.onTapLogin()
    }

    @objc private func onTapSignUp() {
        UrlManager.open(url: "https://coinzix.com/sign-up")
    }

    private func show(error: String) {
        let viewController = BottomSheetModule.viewController(
                image: .local(image: UIImage(named: "warning_2_24")?.withTintColor(.themeLucian)),
                title: "restore.coinzix.login_failed".localized,
                items: [
                    .highlightedDescription(text: error, style: .red)
                ],
                buttons: [
                    .init(style: .yellow, title: "button.ok".localized)
                ]
        )

        present(viewController, animated: true)
    }

}

extension RestoreCoinzixViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "description",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin32),
                    rows: [
                        tableView.descriptionRow(
                                id: "description",
                                text: "restore.coinzix.description".localized,
                                font: .subhead2,
                                textColor: .themeGray,
                                ignoreBottomMargin: true
                        )
                    ]
            ),
            Section(
                id: "username",
                rows: [
                    StaticRow(
                        cell: usernameCell,
                        id: "username",
                        height: .heightSingleLineCell
                    )
                ]
            ),
            Section(
                id: "password",
                headerState: .margin(height: .margin16),
                footerState: .margin(height: .margin32),
                rows: [
                    StaticRow(
                        cell: passwordCell,
                        id: "password",
                        height: .heightSingleLineCell
                    )
                ]
            )
        ]
    }

}
