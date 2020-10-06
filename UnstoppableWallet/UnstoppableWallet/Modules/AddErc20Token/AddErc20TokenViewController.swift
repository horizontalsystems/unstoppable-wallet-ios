import UIKit
import SectionsTableView
import SnapKit
import ThemeKit
import HUD

class AddErc20TokenViewController: ThemeViewController {
    private let delegate: IAddErc20TokenViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private var error: Error?
    private var spinnerVisible = false
    private var viewItem: AddErc20TokenModule.ViewItem?
    private var warningVisible = false
    private var buttonVisible = false

    init(delegate: IAddErc20TokenViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "add_erc20_token.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancelButton))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.registerCell(forClass: InputFieldCell.self)
        tableView.registerCell(forClass: AddErc20TokenSpinnerCell.self)
        tableView.registerCell(forClass: AdditionalDataCell.self)
        tableView.registerCell(forClass: HighlightedDescriptionCell.self)
        tableView.registerCell(forClass: ButtonCell.self)
        tableView.sectionDataSource = self

        tableView.buildSections()
    }

    @objc func onTapCancelButton() {
        delegate.onTapCancel()
    }

    private func inputFieldRow(error: Error?) -> RowProtocol {
        Row<InputFieldCell>(
                id: "input_field",
                hash: error?.localizedDescription,
                dynamicHeight: { containerWidth in
                    InputFieldCell.height(containerWidth: containerWidth, error: error)
                },
                bind: { [weak self] cell, _ in
                    cell.bind(
                            placeholder: "add_erc20_token.contract_address".localized,
                            canEdit: false,
                            error: error,
                            onTextChange: {
                                self?.delegate.onChange(address: $0)
                            }
                    )
                }
        )
    }

    private func warningRow(text: String) -> RowProtocol {
        Row<HighlightedDescriptionCell>(
                id: "warning",
                hash: text,
                dynamicHeight: { containerWidth in
                    HighlightedDescriptionCell.height(containerWidth: containerWidth, text: text)
                },
                bind: { cell, _ in
                    cell.bind(text: text)
                }
        )
    }

    private func spinnerRow() -> RowProtocol {
        Row<AddErc20TokenSpinnerCell>(
                id: "spinner",
                height: .heightSingleLineCell,
                bind: { cell, _ in
                    cell.startAnimating()
                }
        )
    }

    private func additionalDataRow(title: String, value: String?) -> RowProtocol {
        Row<AdditionalDataCell>(
                id: title,
                hash: value,
                height: AdditionalDataCell.height,
                bind: { cell, _ in
                    cell.bind(title: title, value: value, highlighted: true)
                }
        )
    }

    private func buttonRow() -> RowProtocol {
        Row<ButtonCell>(
                id: "add_button",
                height: ButtonCell.height(style: .primaryYellow),
                bind: { [weak self] cell, _ in
                    cell.bind(style: .primaryYellow, title: "button.add".localized) {
                        self?.delegate.onTapAddButton()
                    }
                }
        )
    }

}

extension AddErc20TokenViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var rows: [RowProtocol] = [inputFieldRow(error: error)]

        if spinnerVisible {
            rows.append(spinnerRow())
        }

        if let viewItem = viewItem {
            rows.append(additionalDataRow(title: "add_erc20_token.coin_name".localized, value: viewItem.coinName))
            rows.append(additionalDataRow(title: "add_erc20_token.symbol".localized, value: viewItem.symbol))
            rows.append(additionalDataRow(title: "add_erc20_token.decimals".localized, value: "\(viewItem.decimals)"))
        }

        if warningVisible {
            rows.append(warningRow(text: "add_erc20_token.already_exists".localized))
        }

        if buttonVisible {
            rows.append(buttonRow())
        }

        return [
            Section(
                    id: "main",
                    rows: rows
            )
        ]
    }

}

extension AddErc20TokenViewController: IAddErc20TokenView {

    func set(error: Error?) {
        self.error = error
    }

    func set(spinnerVisible: Bool) {
        self.spinnerVisible = spinnerVisible
    }

    func set(viewItem: AddErc20TokenModule.ViewItem?) {
        self.viewItem = viewItem
    }

    func set(warningVisible: Bool) {
        self.warningVisible = warningVisible
    }

    func set(buttonVisible: Bool) {
        self.buttonVisible = buttonVisible
    }

    func refresh() {
        tableView.reload()
    }

    func showSuccess() {
        HudHelper.instance.showSuccess()
    }

}
