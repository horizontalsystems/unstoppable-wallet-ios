import UIKit
import ThemeKit
import SnapKit
import MarketKit
import ComponentKit
import SectionsTableView
import UIExtensions

protocol IBirthdayInputDelegate: AnyObject {
    func didEnter(birthdayHeight: Int?)
    func didCancelEnterBirthdayHeight()
}

class BirthdayInputViewController: KeyboardAwareViewController {
    private let wrapperViewHeight: CGFloat = .heightButton + .margin32 + .margin16

    private let token: Token
    private weak var delegate: IBirthdayInputDelegate?

    private let iconImageView = UIImageView()
    private let tableView = SectionsTableView(style: .grouped)

    private let gradientWrapperView = GradientView(gradientHeight: .margin16, fromColor: UIColor.themeTyler.withAlphaComponent(0), toColor: UIColor.themeTyler)
    let doneButton = PrimaryButton()

    private let heightInputCell = InputCell(singleLine: true)

    private var isLoaded = false
    private var disclaimerShown = false
    private var walletType: WalletType = .new
    private var didTapDone = false

    init(token: Token, delegate: IBirthdayInputDelegate) {
        self.token = token
        self.delegate = delegate

        super.init(scrollViews: [tableView], accessoryView: gradientWrapperView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        print(" => \(self) Deinit")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "watch_address.title".localized
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: iconImageView)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancel))
        navigationItem.largeTitleDisplayMode = .never

        iconImageView.setImage(withUrlString: token.blockchain.type.imageUrl, placeholder: nil)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionDataSource = self

        heightInputCell.inputPlaceholder = "birthday_input.input_placeholder".localized("000000000")
        heightInputCell.keyboardType = .numberPad
        heightInputCell.isValidText = { Int($0) != nil }
        heightInputCell.onChangeEditing = { [weak self] startEditing in
            self?.onInputCell(inFocus: startEditing)
        }

        view.addSubview(gradientWrapperView)
        gradientWrapperView.snp.makeConstraints { maker in
            maker.height.equalTo(wrapperViewHeight).priority(.high)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        gradientWrapperView.addSubview(doneButton)
        doneButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin32)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).inset(CGFloat.margin16)
        }

        doneButton.set(style: .yellow)
        doneButton.setTitle("button.done".localized, for: .normal)
        doneButton.addTarget(self, action: #selector(onTapDoneButton), for: .touchUpInside)

        setInitialState(bottomPadding: wrapperViewHeight)

        tableView.buildSections()
        isLoaded = true

//        descriptionLabel.text = "birthday_input.description".localized
//        descriptionLabel.numberOfLines = 0
//        descriptionLabel.font = .subhead2
//        descriptionLabel.textColor = .themeGray

//        view.addSubview(heightInputView)
//        heightInputView.snp.makeConstraints { maker in
//            maker.leading.trailing.equalToSuperview()
//            maker.top.equalTo(descriptionLabel.snp.bottom).offset(CGFloat.margin24)
//        }
//
//        heightInputView.inputPlaceholder = "birthday_input.input_placeholder".localized("000000000")
//        heightInputView.keyboardType = .numberPad
//        heightInputView.isValidText = { Int($0) != nil }
//
//        let separatorView = UIView()
//
//        view.addSubview(separatorView)
//        separatorView.snp.makeConstraints { maker in
//            maker.leading.trailing.equalToSuperview()
//            maker.top.equalTo(heightInputView.snp.bottom).offset(CGFloat.margin12)
//            maker.height.equalTo(CGFloat.heightOneDp)
//        }
//
//        separatorView.backgroundColor = .themeSteel10
//
//        view.addSubview(checkboxView)
//
//        let text = "birthday_input.new_wallet".localized
//        let height = CheckboxView.height(containerWidth: view.width, text: text)

//        checkboxView.snp.makeConstraints { maker in
//            maker.leading.trailing.equalToSuperview()
//            maker.top.equalTo(separatorView.snp.bottom)
//            maker.height.equalTo(height)
//        }

//        checkboxView.text = text
//        checkboxView.textColor = .themeLeah
//        checkboxView.checked = false
//
//        checkboxView.addSubview(checkboxButton)
//        checkboxButton.snp.makeConstraints { maker in
//            maker.edges.equalToSuperview()
//        }
//
//        checkboxButton.addTarget(self, action: #selector(onTapCheckBox), for: .touchUpInside)
//
//        let secondSeparatorView = UIView()
//
//        view.addSubview(secondSeparatorView)
//        secondSeparatorView.snp.makeConstraints { maker in
//            maker.leading.trailing.equalToSuperview()
//            maker.top.equalTo(checkboxView.snp.bottom)
//            maker.height.equalTo(CGFloat.heightOneDp)
//        }
//
//        secondSeparatorView.backgroundColor = .themeSteel10
    }


    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if !didTapDone {
            delegate?.didCancelEnterBirthdayHeight()
        }
    }

    private func reloadTable() {
        guard isLoaded else {
            return
        }

        tableView.buildSections()
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    private func onInputCell(inFocus: Bool) {
        guard inFocus else {
            return
        }

        walletType = .old
        tableView.reload(animated: true)

        heightInputCell.textColor = .themeBran
        heightInputCell.accessoryEnabled = true
        if !disclaimerShown {
            showDisclaimer()
        }
    }

    private func showDisclaimer() {
        disclaimerShown = true
        // show disclaimer

        let alertController = InformationModule.simpleInfo(
                title: "alert.warning".localized,
                image: UIImage(named: "circle_information_24"),
                description: "restore_setting.download.disclaimer".localized,
                buttonTitle: "button.ok".localized,
                onTapButton: InformationModule.afterClose { [weak self] in
                    self?.setInputActive()
                },
                onDismiss: {
                    self?.setInputActive()
                })

        return present(alertController.toBottomSheet, animated: true)
    }

    private func setInputActive() {
        heightInputCell.becomeFirstResponder()
    }

    @objc private func onTapCancel() {
        delegate?.didCancelEnterBirthdayHeight()
        dismiss(animated: true)
    }

    @objc private func onTapDoneButton() {
        didTapDone = true
        dismiss(animated: true)
    }

    private func row(type: WalletType) -> RowProtocol {
        CellBuilderNew.row(
                rootElement: .hStack([
                    .text { component in
                        component.font = .body
                        component.textColor = .themeLeah
                        component.text = type.title
                    },
                    .image20 { [weak self] component in
                        component.isHidden = type != self?.walletType
                        component.imageView.image = ComponentKit.image(named: "check_1_20")?.withTintColor(.themeJacob)
                    }
                ]),
                tableView: tableView,
                id: "wallet_type_\(type.title)",
                hash: "wallet_type_\(type.title)_\(type == walletType)",
                height: .heightCell48,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: type.rawValue == 0, isLast: type.rawValue == WalletType.allCases.count - 1)
                }, action: { [weak self] in
                    self?.didTap(type: type)
                }
        )
    }

    private func didTap(type: WalletType) {
        guard type != walletType else {
            return
        }
        switch type {
        case .new:
            walletType = .new
            heightInputCell.textColor = .themeGray
            heightInputCell.accessoryEnabled = false
            view.endEditing(true)
        case .old:
            walletType = .old
            heightInputCell.textColor = .themeBran
            heightInputCell.accessoryEnabled = true

            if !disclaimerShown {
                showDisclaimer()
            } else {
                setInputActive()
            }
        }

        tableView.reload(animated: true)
    }

}
extension BirthdayInputViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(id: "top-margin", headerState: .margin(height: .margin12)),
            Section(
                    id: "wallet-type",
                    footerState: .margin(height: .margin24),
                    rows: WalletType.allCases.map {
                        row(type: $0)
                    }
            ),
            Section(
                    id: "input_height",
                    headerState: tableView.sectionHeader(text: "birthday_input.title".localized),
                    footerState: tableView.sectionFooter(text: "birthday_input.description".localized),
                    rows: [
                        StaticRow(
                                cell: heightInputCell,
                                id: "height-input",
                                height: .heightSingleLineCell
                        )
                    ]
            )
        ]
    }

}

extension BirthdayInputViewController {
    enum WalletType: Int, CaseIterable {
        case new, old

        var title: String {
            switch self {
            case .new: return "birthday_input.new_wallet".localized
            case .old: return "birthday_input.old_wallet".localized;
            }
        }
    }
}
