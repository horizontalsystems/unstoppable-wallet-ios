import ThemeKit
import SnapKit
import SectionsTableView
import RxSwift
import RxCocoa

class AddTokenViewController: ThemeViewController {
    private let viewModel: AddTokenViewModel
    private let pageTitle: String
    private let referenceTitle: String

    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private var error: Error?
    private var loading = false
    private var viewItem: AddTokenViewModel.ViewItem?
    private var warningVisible = false
    private var buttonVisible = false

    init(viewModel: AddTokenViewModel, pageTitle: String, referenceTitle: String) {
        self.viewModel = viewModel
        self.pageTitle = pageTitle
        self.referenceTitle = referenceTitle

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = pageTitle
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancelButton))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.sectionDataSource = self

        tableView.registerCell(forClass: InputFieldCell.self)
        tableView.registerCell(forClass: AddTokenSpinnerCell.self)
        tableView.registerCell(forClass: AdditionalDataCell.self)
        tableView.registerCell(forClass: HighlightedDescriptionCell.self)
        tableView.registerCell(forClass: ButtonCell.self)

        subscribe(disposeBag, viewModel.loadingDriver) { [weak self] loading in
            self?.loading = loading
            self?.tableView.reload()
        }
        subscribe(disposeBag, viewModel.viewItemDriver) { [weak self] viewItem in
            self?.viewItem = viewItem
            self?.tableView.reload()
        }
        subscribe(disposeBag, viewModel.warningVisibleDriver) { [weak self] visible in
            self?.warningVisible = visible
            self?.tableView.reload()
        }
        subscribe(disposeBag, viewModel.buttonVisibleDriver) { [weak self] visible in
            self?.buttonVisible = visible
            self?.tableView.reload()
        }
        subscribe(disposeBag, viewModel.errorDriver) { [weak self] error in
            self?.error = error
            self?.tableView.reload()
        }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in
            HudHelper.instance.showSuccess()
            self?.dismiss(animated: true)
        }
    }

    @objc private func onTapCancelButton() {
        dismiss(animated: true)
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
                            placeholder: self?.referenceTitle,
                            canEdit: false,
                            error: error,
                            onTextChange: {
                                self?.viewModel.onEnter(reference: $0)
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
        Row<AddTokenSpinnerCell>(
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
                        self?.viewModel.onTapButton()
                    }
                }
        )
    }

}

extension AddTokenViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var rows: [RowProtocol] = [inputFieldRow(error: error)]

        if loading {
            rows.append(spinnerRow())
        }

        if let viewItem = viewItem {
            rows.append(additionalDataRow(title: "add_token.coin_name".localized, value: viewItem.coinName))
            rows.append(additionalDataRow(title: "add_token.symbol".localized, value: viewItem.symbol))
            rows.append(additionalDataRow(title: "add_token.decimals".localized, value: "\(viewItem.decimals)"))
        }

        if warningVisible {
            rows.append(warningRow(text: "add_token.already_exists".localized))
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
