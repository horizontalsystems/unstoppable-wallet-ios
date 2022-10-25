import UIKit
import ThemeKit
import ComponentKit
import UIExtensions
import SnapKit
import MarketKit
import SectionsTableView

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

    override func viewDidLoad() {
        super.viewDidLoad()

        title = token.coin.name
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: iconImageView)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancel))
        navigationItem.largeTitleDisplayMode = .never

        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(CGFloat.iconSize24)
        }
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
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if !didTapDone {
            delegate?.didCancelEnterBirthdayHeight()
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

        let title = BottomSheetItem.ComplexTitleViewItem(title: "alert.warning".localized, image: UIImage(named: "circle_information_24")?.withTintColor(.themeJacob))
        let description = InformationModule.Item.description(text: "restore_setting.download.disclaimer".localized, isHighlighted: true)
        let continueButton = InformationModule.ButtonItem(style: .yellow, title: "button.continue".localized, action: InformationModule.afterClose { [weak self] in
            self?.setOldTypeActive(showKeyboard: showKeyboard)
        })
        let cancelButton = InformationModule.ButtonItem(style: .transparent, title: "button.cancel".localized, action: InformationModule.afterClose())
        let alertController = InformationModule.viewController(title: .complex(viewItem: title), items: [description], buttons: [continueButton, cancelButton])

        return present(alertController, animated: true)
    }

    private func setOldTypeActive(showKeyboard: Bool = true) {
        setActive(type: .old)
        tableView.reload(animated: true)

        if showKeyboard {
            _ = heightInputCell.becomeFirstResponder()
        }
    }

    @objc private func onTapCancel() {
        delegate?.didCancelEnterBirthdayHeight()
        dismiss(animated: true)
    }

    @objc private func onTapDoneButton() {
        didTapDone = true

        if walletType == .new {
            delegate?.didEnter(birthdayHeight: nil)
        } else {
            let birthdayHeight = heightInputCell.inputText.flatMap { Int($0) } ?? 0
            delegate?.didEnter(birthdayHeight: birthdayHeight)
        }

        dismiss(animated: true)
    }

    private func row(type: WalletType) -> RowProtocol {
        CellBuilderNew.row(
            rootElement: .hStack([
                .vStackCentered([
                    .text { component in
                        component.font = .body
                        component.textColor = .themeLeah
                        component.text = type.title
                    },
                    .margin(3),
                    .text { component in
                        component.font = .subhead2
                        component.textColor = .themeGray
                        component.text = type.description
                    },
                ]
                ),
                .image20 { [weak self] component in
                    component.isHidden = type != self?.walletType
                    component.imageView.image = ComponentKit.image(named: "check_1_20")?.withTintColor(.themeJacob)
                },
            ]),
            tableView: tableView,
            id: "wallet_type_\(type.title)",
            hash: "wallet_type_\(type.title)_\(type == walletType)",
            height: .heightDoubleLineCell,
            autoDeselect: true,
            bind: { cell in
                cell.set(backgroundStyle: .lawrence, isFirst: type.rawValue == 0, isLast: type.rawValue == WalletType.allCases.count - 1)
            }, action: { [weak self] in
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
