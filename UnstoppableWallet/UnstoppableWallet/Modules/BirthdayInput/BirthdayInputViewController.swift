import UIKit
import ThemeKit
import ComponentKit
import UIExtensions
import SnapKit
import MarketKit
import SectionsTableView

class BirthdayInputViewController: KeyboardAwareViewController {
    private let token: Token

    var onEnterBirthdayHeight: ((Int?) -> ())?
    var onCancel: (() -> ())?

    private let iconImageView = UIImageView()
    private let tableView = SectionsTableView(style: .grouped)

    private let gradientWrapperView = BottomGradientHolder()
    let doneButton = PrimaryButton()

    private let heightInputCell = InputCell(singleLine: true)

    private var isLoaded = false
    private var disclaimerShown = false
    private var walletType: WalletType = .new
    private var didTapDone = false

    init(token: Token) {
        self.token = token

        super.init(scrollViews: [tableView], accessoryView: gradientWrapperView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = token.coin.name
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: iconImageView)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancel))
        navigationItem.largeTitleDisplayMode = .never

        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(CGFloat.iconSize24)
        }
        iconImageView.setImage(withUrlString: token.blockchain.type.imageUrl, placeholder: UIImage(named: token.placeholderImageName))

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

        gradientWrapperView.add(to: self)
        gradientWrapperView.addSubview(doneButton)

        doneButton.set(style: .yellow)
        doneButton.setTitle("button.done".localized, for: .normal)
        doneButton.addTarget(self, action: #selector(onTapDoneButton), for: .touchUpInside)

        tableView.buildSections()
        isLoaded = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if !didTapDone {
            onCancel?()
        }
    }

    private func onInputCell(inFocus: Bool) {
        guard inFocus else {
            return
        }

        if !disclaimerShown {
            showDisclaimer()
        } else {
            setOldTypeActive()
        }
    }

    private func showDisclaimer(showKeyboard: Bool = true) {
        disclaimerShown = true
        // show disclaimer

        let viewController = BottomSheetModule.viewController(
                image: .local(image: UIImage(named: "warning_2_24")?.withTintColor(.themeJacob)),
                title: "alert.warning".localized,
                items: [
                    .highlightedDescription(text: "restore_setting.download.disclaimer".localized)
                ],
                buttons: [
                    .init(style: .yellow, title: "button.continue".localized, actionType: .afterClose) { [ weak self] in self?.setOldTypeActive(showKeyboard: showKeyboard) },
                    .init(style: .transparent, title: "button.cancel".localized)
                ]
        )

        present(viewController, animated: true)
    }

    private func setOldTypeActive(showKeyboard: Bool = true) {
        setActive(type: .old)
        tableView.reload(animated: true)

        if showKeyboard {
            _ = heightInputCell.becomeFirstResponder()
        }
    }

    @objc private func onTapCancel() {
        onCancel?()
        dismiss(animated: true)
    }

    @objc private func onTapDoneButton() {
        didTapDone = true

        if walletType == .new {
            onEnterBirthdayHeight?(nil)
        } else {
            let birthdayHeight = heightInputCell.inputText.flatMap { Int($0) } ?? 0
            onEnterBirthdayHeight?(birthdayHeight)
        }

        dismiss(animated: true)
    }

    private func row(type: WalletType) -> RowProtocol {
        tableView.universalRow62(
                id: "wallet_type_\(type.title)",
                title: .body(type.title),
                description: .subhead2(type.description),
                accessoryType: .check(type == walletType),
                hash: "wallet_type_\(type.title)_\(type == walletType)",
                autoDeselect: true,
                isFirst: type.rawValue == 0,
                isLast: type.rawValue == WalletType.allCases.count - 1,
                action: { [weak self] in
                    self?.didTap(type: type)
                }
        )
    }

    private func setActive(type: WalletType) {
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
        }
    }

    private func didTap(type: WalletType) {
        guard type != walletType else {
            return
        }
        switch type {
        case .new:
            setActive(type: .new)
        case .old:
            if !disclaimerShown {
                showDisclaimer(showKeyboard: false)
                return
            } else {
                setOldTypeActive(showKeyboard: false)
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
                    ),
                ]
            ),
        ]
    }
}

extension BirthdayInputViewController {
    enum WalletType: Int, CaseIterable {
        case new, old

        var title: String {
            switch self {
            case .new: return "birthday_input.new_wallet".localized
            case .old: return "birthday_input.old_wallet".localized
            }
        }

        var description: String {
            switch self {
            case .new: return "birthday_input.new_wallet.description".localized
            case .old: return "birthday_input.old_wallet.description".localized
            }
        }
    }
}
