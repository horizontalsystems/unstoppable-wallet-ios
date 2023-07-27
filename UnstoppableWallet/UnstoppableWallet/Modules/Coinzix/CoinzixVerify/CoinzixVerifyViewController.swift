import Combine
import UIKit
import SnapKit
import ThemeKit
import ComponentKit
import SectionsTableView
import HUD
import UIExtensions

class CoinzixVerifyViewController: KeyboardAwareViewController {
    private let viewModel: CoinzixVerifyViewModel
    private var cancellables = Set<AnyCancellable>()

    private weak var returnViewController: UIViewController?

    private let tableView = SectionsTableView(style: .grouped)

    private let emailPinInputCell = ResendPasteInputCell()
    private let googlePinInputCell = PasteInputCell()

    private let buttonsHolder = BottomGradientHolder()
    private let submitButton = PrimaryButton()
    private let submittingButton = PrimaryButton()
    private var isLoaded = false

    init(viewModel: CoinzixVerifyViewModel, returnViewController: UIViewController?) {
        self.viewModel = viewModel
        self.returnViewController = returnViewController

        super.init(scrollViews: [tableView], accessoryView: buttonsHolder)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "coinzix_verify.title".localized

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancel))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        tableView.sectionDataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        emailPinInputCell.inputPlaceholder = "coinzix_verify.email_pin".localized
        emailPinInputCell.keyboardType = .numberPad
        emailPinInputCell.onChangeHeight = { [weak self] in self?.reloadHeights() }
        emailPinInputCell.onChangeText = { [weak self] in self?.viewModel.onChange(emailPin: $0 ?? "") }
        emailPinInputCell.onFetchText = { [weak self] in
            self?.viewModel.onChange(emailPin: $0 ?? "")
            self?.emailPinInputCell.inputText = $0
        }
        emailPinInputCell.onResend = { [weak self] in self?.viewModel.onTapResend() }

        googlePinInputCell.inputPlaceholder = "coinzix_verify.google_pin".localized
        googlePinInputCell.keyboardType = .numberPad
        googlePinInputCell.onChangeHeight = { [weak self] in self?.reloadHeights() }
        googlePinInputCell.onChangeText = { [weak self] in self?.viewModel.onChange(googlePin: $0 ?? "") }
        googlePinInputCell.onFetchText = { [weak self] in
            self?.viewModel.onChange(googlePin: $0 ?? "")
            self?.googlePinInputCell.inputText = $0
        }

        buttonsHolder.add(to: self)

        buttonsHolder.addSubview(submitButton)
        submitButton.set(style: .yellow)
        submitButton.setTitle("coinzix_verify.submit".localized, for: .normal)
        submitButton.addTarget(self, action: #selector(onTapSubmit), for: .touchUpInside)

        buttonsHolder.addSubview(submittingButton)
        submittingButton.set(style: .gray, accessoryType: .spinner)
        submittingButton.isEnabled = false
        submittingButton.setTitle("coinzix_verify.submit".localized, for: .normal)

        viewModel.$submitButtonState
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.sync(submitButtonState: $0) }
                .store(in: &cancellables)

        viewModel.$resendEnabled
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.emailPinInputCell.isResendEnabled = $0 }
                .store(in: &cancellables)

        viewModel.successPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.confirmSubmit() }
                .store(in: &cancellables)

        viewModel.errorPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.show(error: $0) }
                .store(in: &cancellables)

        tableView.buildSections()
        isLoaded = true
    }

    private func reloadHeights() {
        guard isLoaded else {
            return
        }

        UIView.animate(withDuration: 0.2) {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }

    private func sync(submitButtonState: AsyncActionButtonState) {
        switch submitButtonState {
        case .disabled:
            submitButton.isHidden = false
            submitButton.isEnabled = false
            submittingButton.isHidden = true
            emailPinInputCell.isEnabled = true
            googlePinInputCell.isEnabled = true

        case .enabled:
            submitButton.isHidden = false
            submitButton.isEnabled = true
            submittingButton.isHidden = true
            emailPinInputCell.isEnabled = true
            googlePinInputCell.isEnabled = true

        case .spinner:
            submitButton.isHidden = true
            submitButton.isEnabled = false
            submittingButton.isHidden = false
            emailPinInputCell.isEnabled = false
            googlePinInputCell.isEnabled = false
        }
    }

    private func confirmSubmit() {
        (returnViewController ?? self).dismiss(animated: true)
    }

    @objc private func onTapCancel() {
        (returnViewController ?? self).dismiss(animated: true)
    }

    @objc private func onTapSubmit() {
        view.endEditing(true)
        viewModel.onTapSubmit()
    }

    private func show(error: String) {
        let viewController = BottomSheetModule.viewController(
                image: .local(image: UIImage(named: "warning_2_24")?.withTintColor(.themeLucian)),
                title: "coinzix_verify.failed".localized,
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

extension CoinzixVerifyViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        for type in viewModel.twoFactorTypes {
            switch type {
            case .email:
                sections.append(contentsOf: [
                    Section(
                            id: "email-pin",
                            headerState: .margin(height: .margin32),
                            rows: [
                                StaticRow(
                                        cell: emailPinInputCell,
                                        id: "email-pin",
                                        dynamicHeight: { [weak self] width in
                                            self?.emailPinInputCell.height(containerWidth: width) ?? 0
                                        }
                                )
                            ]
                    ),
                    Section(
                            id: "email-pin-description",
                            rows: [
                                tableView.descriptionRow(
                                        id: "email-pin-description",
                                        text: "coinzix_verify.email_pin.description".localized,
                                        font: .subhead2,
                                        textColor: .themeGray,
                                        ignoreBottomMargin: true
                                )
                            ]
                    ),
                ])

            case .authenticator:
                sections.append(contentsOf: [
                    Section(
                            id: "google-pin",
                            headerState: .margin(height: .margin32),
                            rows: [
                                StaticRow(
                                        cell: googlePinInputCell,
                                        id: "google-pin",
                                        dynamicHeight: { [weak self] width in
                                            self?.googlePinInputCell.height(containerWidth: width) ?? 0
                                        }
                                )
                            ]
                    ),
                    Section(
                            id: "google-pin-description",
                            footerState: .margin(height: .margin32),
                            rows: [
                                tableView.descriptionRow(
                                        id: "google-pin-description",
                                        text: "coinzix_verify.google_pin.description".localized,
                                        font: .subhead2,
                                        textColor: .themeGray,
                                        ignoreBottomMargin: true
                                )
                            ]
                    )
                ])
            }
        }

        return sections
    }

}
