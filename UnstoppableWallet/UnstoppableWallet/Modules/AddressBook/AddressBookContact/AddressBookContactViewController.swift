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

    private let tableView = SectionsTableView(style: .grouped)
    private var viewItem: AddressBookContactViewModel.ViewItem?
    private var isLoaded = false

    private let nameCell = InputCell()
    private let nameCautionCell = FormCautionCell()

    private var addAddressEnabled: Bool = true

    init(viewModel: AddressBookContactViewModel, presented: Bool) {
        self.viewModel = viewModel
        self.presented = presented

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.title

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.save".localized, style: .done, target: self, action: #selector(onTapSaveButton))
        if presented {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .done, target: self, action: #selector(onTapCancelButton))
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionDataSource = self

        tableView.buildSections()

        nameCell.inputText = viewModel.initialName
        nameCell.onChangeText = { [weak self] in self?.viewModel.onChange(name: $0) }

        nameCautionCell.onChangeHeight = { [weak self] in self?.onChangeHeight() }

        subscribe(disposeBag, viewModel.saveEnabledDriver) { [weak self] enabled in
            self?.navigationItem.rightBarButtonItem?.isEnabled = enabled
        }

        subscribe(disposeBag, viewModel.nameAlreadyExistErrorDriver) { [weak self] exist in
            self?.nameCell.set(cautionType: exist ? .error : nil)
            self?.nameCautionCell.set(caution: exist ? Caution(text: "name already exist", type: .error) : nil)
        }
        subscribe(disposeBag, viewModel.allAddressesUsedDriver) { [weak self] allUsed in
            self?.addAddressEnabled = !allUsed
            self?.tableView.reload()
        }

        isLoaded = true
    }

//    private func open(controller: UIViewController) {
//        navigationItem.searchController?.dismiss(animated: true)
//        present(controller, animated: true)
//    }
//

    @objc private func onTapCancelButton() {
        dismiss(animated: true)
    }

    @objc private func onTapSaveButton() {
        //
    }

    private func onTapAddAddress() {

    }

}

extension AddressBookContactViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
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
            ),
            Section(id: "actions",
                    footerState: .margin(height: .margin32),
                    rows: [
                        tableView.universalRow48(
                                id: "add_address",
                                image: .local(UIImage(named: "plus_24")?.withTintColor(addAddressEnabled ? .themeJacob : .themeGray)),
                                title: .body("Add Address", color: addAddressEnabled ? .themeJacob : .themeGray),
                                autoDeselect: true,
                                isFirst: true,
                                isLast: true, action: addAddressEnabled ? { [weak self] in

                                self?.onTapAddAddress()
                        } : nil)
                    ])
        ]
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
