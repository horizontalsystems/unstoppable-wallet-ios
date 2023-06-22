import Combine
import UIKit
import SnapKit
import ThemeKit
import ComponentKit
import SectionsTableView
import HUD
import HCaptcha

class RestoreCoinzixViewController: KeyboardAwareViewController {
    private let wrapperViewHeight: CGFloat = .heightButton + .margin16 + .heightButton
    private let hcaptcha: HCaptcha
    private let viewModel: RestoreCoinzixViewModel
    private var webView: UIView?
    private var cancellables = Set<AnyCancellable>()

    private weak var returnViewController: UIViewController?

    private let tableView = SectionsTableView(style: .grouped)

    private let usernameCell = TextFieldCell()
    private let passwordCell = PasswordInputCell()

    private let buttonsHolder = BottomGradientHolder()
    private let loginButton = PrimaryButton()
    private let logginInButton = PrimaryButton()

    private var isLoaded = false

    init(hCaptchaKey: String, viewModel: RestoreCoinzixViewModel, returnViewController: UIViewController?) {
        hcaptcha = try! HCaptcha(apiKey: hCaptchaKey, baseURL: URL(string: "https://api.coinzix.com"))
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

        tableView.registerCell(forClass: DescriptionCell.self)
        tableView.sectionDataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        usernameCell.inputPlaceholder = "restore.coinzix.sample_username".localized
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

        stackView.addArrangedSubview(logginInButton)
        logginInButton.set(style: .yellow, accessoryType: .spinner)
        logginInButton.isEnabled = false
        logginInButton.setTitle("restore.coinzix.login".localized, for: .normal)

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

        viewModel.$logginInVisible
            .receive(on: DispatchQueue.main)
            .sink { [weak self] visible in self?.logginInButton.isHidden = !visible }
            .store(in: &cancellables)

        viewModel.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { text in HudHelper.instance.showErrorBanner(title: text) }
            .store(in: &cancellables)

        viewModel.successPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                HudHelper.instance.show(banner: .imported)
                (self?.returnViewController ?? self)?.dismiss(animated: true)
            }
            .store(in: &cancellables)

        additionalContentInsets = UIEdgeInsets(top: 0, left: 0, bottom: -.margin16, right: 0)
        additionalInsetsOnlyForClosedKeyboard = false
        ignoreSafeAreaForAccessoryView = false

        tableView.buildSections()
        isLoaded = true

        hcaptcha.configureWebView { [weak self] webview in
            webview.frame = self?.view.bounds ?? CGRect.zero
            self?.webView = webview
        }
    }

    @objc private func onTapCancel() {
        dismiss(animated: true)
    }

    @objc private func onTapLogin() {
        view.endEditing(true)

        hcaptcha.validate(on: self.view) { [weak self] result in
            do {
                self?.viewModel.login(captchaToken: try result.dematerialize())
            } catch {
                print("ERROR: \(error)")
            }

            self?.webView?.removeFromSuperview()
        }
    }

    @objc private func onTapSignUp() {
        UrlManager.open(url: "https://coinzix.com/sign-up")
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
                    Row<DescriptionCell>(
                        id: "description-cell",
                        dynamicHeight: { containerWidth in
                            DescriptionCell.height(containerWidth: containerWidth, text: "restore.coinzix.description".localized, font: .subhead2, ignoreBottomMargin: true)
                        },
                        bind: { cell, _ in
                            cell.label.text = "restore.coinzix.description".localized
                            cell.label.font = .subhead2
                            cell.label.textColor = .themeGray
                        }
                    )
                ]
            ),
            Section(
                id: "username",
                headerState: .margin(height: .margin12),
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
