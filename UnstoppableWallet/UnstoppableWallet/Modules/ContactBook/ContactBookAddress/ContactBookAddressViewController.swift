import UIKit
import Foundation
import RxSwift
import RxCocoa
import SectionsTableView
import ComponentKit
import ThemeKit
import UIExtensions

class ContactBookAddressViewController: KeyboardAwareViewController {
    private let viewModel: ContactBookAddressViewModel
    private let onUpdateAddress: (ContactAddress?) -> ()
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private var isLoaded = false
    private var addressWasChanged = false {
        didSet {
            handleChangeAddress()
        }
    }

    private let recipientCell: RecipientAddressInputCell
    private let recipientCautionCell: RecipientAddressCautionCell

    private let gradientWrapperView: BottomGradientHolder?
    private let doneButton: PrimaryButton?

    private var blockchainName: String = ""
    private var addAddressEnabled: Bool = true

    init(viewModel: ContactBookAddressViewModel, addressViewModel: RecipientAddressViewModel, onUpdateAddress: @escaping (ContactAddress?) -> ()) {
        self.viewModel = viewModel
        recipientCell = RecipientAddressInputCell(viewModel: addressViewModel)
        recipientCautionCell = RecipientAddressCautionCell(viewModel: addressViewModel)
        self.onUpdateAddress = onUpdateAddress

        if !viewModel.existAddress {
            gradientWrapperView = BottomGradientHolder()
            doneButton = PrimaryButton()
        } else {
            gradientWrapperView = nil
            doneButton = nil
        }

        super.init(scrollViews: [tableView], accessoryView: gradientWrapperView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.title
        navigationItem.largeTitleDisplayMode = .never

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .done, target: self, action: #selector(onTapSaveButton))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onCloseConfirmation))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionDataSource = self

        if let gradientWrapperView {
            gradientWrapperView.add(to: self)
            gradientWrapperView.isHidden = viewModel.existAddress
        }

        if let doneButton {
            gradientWrapperView?.addSubview(doneButton)

            doneButton.set(style: .yellow)
            doneButton.setTitle("button.done".localized, for: .normal)
            doneButton.addTarget(self, action: #selector(onTapSaveButton), for: .touchUpInside)
        }
        tableView.buildSections()

        recipientCell.set(inputText: viewModel.initialAddress)

        recipientCell.onChangeHeight = { [weak self] in
            self?.onChangeHeight()
        }
        recipientCell.onOpenViewController = { [weak self] in
            self?.present($0, animated: true)
        }

        recipientCautionCell.onChangeHeight = { [weak self] in self?.onChangeHeight() }

        subscribe(disposeBag, viewModel.saveEnabledDriver) { [weak self] enabled in
            self?.addressWasChanged = enabled
            self?.doneButton?.isEnabled = enabled
        }
        subscribe(disposeBag, viewModel.blockchainNameDriver) { [weak self] name in
            self?.blockchainName = name
            self?.tableView.reload()
        }

        isLoaded = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isModalInPresentation = addressWasChanged
    }

    private func handleChangeAddress() {
        navigationItem.rightBarButtonItem?.isEnabled = addressWasChanged
        isModalInPresentation = addressWasChanged
    }

    @objc private func onClose() {
        dismiss(animated: true)
    }

    @objc private func onCloseConfirmation() {
        if addressWasChanged {
            let viewController = BottomSheetModule.viewController(
                    image: .local(image: UIImage(named: "warning_2_24")?.withTintColor(.themeJacob)),
                    title: "alert.warning".localized,
                    items: [
                        .highlightedDescription(text: "contacts.contact.dismiss_changes.description".localized)
                    ],
                    buttons: [
                        .init(style: .red, title: "contacts.contact.dismiss_changes.discard_changes".localized, actionType: .afterClose) { [ weak self] in
                            self?.onClose()
                        },
                        .init(style: .transparent, title: "contacts.contact.dismiss_changes.keep_editing".localized)
                    ]
            )
            present(viewController, animated: true)
        } else {
            onClose()
        }
    }

    @objc private func onTapSaveButton() {
        if let contactAddress = viewModel.contactAddress {
            onUpdateAddress(contactAddress)
            onClose()
        }
    }

    private func onTapDeleteAddress() {
        let viewController = BottomSheetModule.viewController(
                image: .local(image: UIImage(named: "warning_2_24")?.withTintColor(.themeJacob)),
                title: "contacts.add_address.delete_alert.title".localized,
                items: [
                    .highlightedDescription(text: "contacts.add_address.delete_alert.description".localized)
                ],
                buttons: [
                    .init(style: .red, title: "contacts.add_address.delete_alert.delete".localized, actionType: .afterClose) { [ weak self] in
                        self?.onUpdateAddress(nil)
                        self?.dismiss(animated: true)
                    },
                    .init(style: .transparent, title: "button.cancel".localized)
                ]
        )

        present(viewController, animated: true)
    }

    private func onTapBlockchain() {
        let viewController = SelectorModule.singleSelectorViewController(
                title: "contacts.contact.address.blockchains".localized,
                viewItems: viewModel.blockchainViewItems,
                onSelect: { [weak self] in
                    self?.viewModel.setBlockchain(index: $0)
                }
        )

        present(viewController, animated: true)
    }

    private var blockchainRow: RowProtocol {
        tableView.universalRow48(
            id: "blockchain",
            title: .subhead2("contacts.contact.address.blockchain".localized),
            value: .subhead1(blockchainName),
            accessoryType: viewModel.existAddress ? .none : .dropdown,
            autoDeselect: true,
            isFirst: true,
            isLast: true,
            action: viewModel.existAddress ? nil : { [weak self] in self?.onTapBlockchain() })
    }

}

extension ContactBookAddressViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections = [
            Section(id: "actions",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin32),
                    rows: [blockchainRow]),
            Section(
                    id: "name",
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: recipientCell,
                                id: "name",
                                dynamicHeight: { [weak self] width in
                                    self?.recipientCell.height(containerWidth: width) ?? 0
                                }
                        ),
                        StaticRow(
                                cell: recipientCautionCell,
                                id: "name-caution",
                                dynamicHeight: { [weak self] width in
                                    self?.recipientCautionCell.height(containerWidth: width) ?? 0
                                }
                        )
                    ]
            )
        ]
        if viewModel.existAddress {
            sections.append(
                        Section(id: "actions",
                        footerState: .margin(height: .margin32),
                        rows: [
                            tableView.universalRow48(
                                    id: "delete_address",
                                    image: .local(UIImage(named: "trash_24")?.withTintColor(.themeLucian)),
                                    title: .body("contacts.contact.address.delete_address".localized, color: .themeLucian),
                                    autoDeselect: true,
                                    isFirst: true,
                                    isLast: true,
                                    action: { [weak self] in
                                        self?.onTapDeleteAddress()
                                    }
                            )
                        ])
            )
        }
        return sections
    }

}

extension ContactBookAddressViewController: IDynamicHeightCellDelegate {

    func onChangeHeight() {
        guard isLoaded else {
            return
        }

        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.tableView.beginUpdates()
            self?.tableView.endUpdates()
        }
    }

}
