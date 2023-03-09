import UIKit
import Foundation
import RxSwift
import RxCocoa
import SectionsTableView
import ComponentKit
import ThemeKit

class AddressBookContactViewController: ThemeViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: AddressBookContactViewModel
    private let presented: Bool
    private let onUpdateContact: (Contact?) -> ()
    private let deleteContactHidden: Bool

    private let tableView = SectionsTableView(style: .grouped)
    private var viewItem: AddressBookContactViewModel.ViewItem?
    private var isLoaded = false

    private let nameCell = InputCell()
    private let nameCautionCell = FormCautionCell()

    private var addressViewItems: [AddressBookContactViewModel.AddressViewItem] = []
    private var addAddressHidden: Bool = false

    init(viewModel: AddressBookContactViewModel, presented: Bool, onUpdateContact: @escaping (Contact?) -> ()) {
        self.viewModel = viewModel
        self.presented = presented
        self.onUpdateContact = onUpdateContact
        deleteContactHidden = !viewModel.editExisting

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.title
        navigationItem.largeTitleDisplayMode = .never

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.save".localized, style: .done, target: self, action: #selector(onTapSaveButton))
        if presented {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancelButton))
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionDataSource = self
        tableView.keyboardDismissMode = .interactive

        tableView.buildSections()

        nameCell.inputText = viewModel.initialName
        nameCell.onChangeText = { [weak self] in self?.viewModel.onChange(name: $0) }

        nameCautionCell.onChangeHeight = { [weak self] in self?.onChangeHeight() }

        subscribe(disposeBag, viewModel.saveEnabledDriver) { [weak self] enabled in
            self?.navigationItem.rightBarButtonItem?.isEnabled = enabled
        }

        subscribe(disposeBag, viewModel.nameAlreadyExistErrorDriver) { [weak self] exist in
            self?.nameCell.set(cautionType: exist ? .error : nil)
            self?.nameCautionCell.set(caution: exist ? Caution(text: "contacts.contact.update.error.name_already_exist".localized, type: .error) : nil)
        }
        subscribe(disposeBag, viewModel.addressViewItemsDriver) { [weak self] viewItems in
            self?.addressViewItems = viewItems
            self?.tableView.reload()
        }
        subscribe(disposeBag, viewModel.hideAddAddressDriver) { [weak self] allUsed in
            self?.addAddressHidden = allUsed
            self?.tableView.reload()
        }

        isLoaded = true
    }

    @objc private func onTapCancelButton() {
        dismiss(animated: true)
    }

    @objc private func onTapSaveButton() {
        if let contact = viewModel.contact {
            onUpdateContact(contact)
            dismiss(animated: true)
        }
    }

    private func onTapDeleteContact() {
        onUpdateContact(nil)

        dismiss(animated: true)
    }

    private func onTapUpdateAddress(address: ContactAddress? = nil) {
        let onSaveAddress: (ContactAddress?) -> () = { [weak self] updatedAddress in
            if let updatedAddress {
                self?.viewModel.updateContact(address: updatedAddress)
            } else {
                self?.viewModel.removeContact(address: address)
            }
        }
        guard let controller = AddressBookAddressModule.viewController(existAddresses: viewModel.existAddresses, currentAddress: address, onSaveAddress: onSaveAddress) else {
            return
        }

        present(controller, animated: true)
    }

}

extension AddressBookContactViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections = [
            Section(
                    id: "name",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: nameCell,
                                id: "name",
                                dynamicHeight: { [weak self] width in
                                    self?.nameCell.height(containerWidth: width) ?? 0
                                }
                        ),
                        StaticRow(
                                cell: nameCautionCell,
                                id: "name-caution",
                                dynamicHeight: { [weak self] width in
                                    self?.nameCautionCell.height(containerWidth: width) ?? 0
                                }
                        )
                    ]
            )]
        if !addressViewItems.isEmpty {
            sections.append(
                    Section(
                        id: "addresses",
                        footerState: .margin(height: .margin32),
                        rows: addressViewItems.enumerated().map({ (index, viewItem) -> RowProtocol in
                            CellComponent.blockchainAddress(
                                    tableView: tableView,
                                    rowInfo: RowInfo(index: index, count: addressViewItems.count),
                                    imageUrl: viewItem.blockchainImageUrl,
                                    title: viewItem.blockchainName,
                                    value: viewItem.address,
                                    editType: viewItem.edited ? .edited : .original
                            ) { [weak self] in
                                self?.onTapUpdateAddress(address: ContactAddress(blockchainUid: viewItem.blockchainUid, address: viewItem.address))
                            }
                        })
                    )
            )
        }
        var cells = [RowProtocol]()
        if !addAddressHidden {
            cells.append(
                    tableView.universalRow48(
                            id: "add_address",
                            image: .local(UIImage(named: "plus_24")?.withTintColor(.themeJacob)),
                            title: .body("contacts.contact.add_address".localized, color: .themeJacob),
                            autoDeselect: true,
                            isFirst: true,
                            isLast: deleteContactHidden,
                            action: { [weak self] in
                                self?.onTapUpdateAddress()
                            }
                    )
            )
        }
        if !deleteContactHidden {
            cells.append(
                    tableView.universalRow48(
                            id: "delete_contact",
                            image: .local(UIImage(named: "trash_24")?.withTintColor(.themeLucian)),
                            title: .body("contacts.contact.delete".localized, color: .themeLucian),
                            autoDeselect: true,
                            isFirst: addAddressHidden,
                            isLast: true,
                            action: { [weak self] in
                                self?.onTapDeleteContact()
                            }
                    )
            )
        }

        if !cells.isEmpty {
            sections.append(Section(id: "actions",
                    footerState: .margin(height: .margin32),
                    rows: cells)
            )
        }

        return sections
    }

}

extension AddressBookContactViewController: IDynamicHeightCellDelegate {

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
