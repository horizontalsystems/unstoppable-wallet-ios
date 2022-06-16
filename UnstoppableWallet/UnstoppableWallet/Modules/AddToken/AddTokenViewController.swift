import ThemeKit
import SnapKit
import SectionsTableView
import RxSwift
import RxCocoa
import ComponentKit

class AddTokenViewController: ThemeViewController {
    private let viewModel: AddTokenViewModel

    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private let inputCell = AddressInputCell()
    private let inputCautionCell = FormCautionCell()

    private let addButtonHolder = BottomGradientHolder()
    private let addButton = ThemeButton()

    private var viewItem: AddTokenViewModel.ViewItem?
    private var isLoaded = false

    init(viewModel: AddTokenViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "add_token.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancelButton))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.sectionDataSource = self
        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)

        inputCell.isEditable = false
        inputCell.inputPlaceholder = "add_token.input_placeholder".localized
        inputCell.onChangeHeight = { [weak self] in self?.reloadHeights() }
        inputCell.onChangeText = { [weak self] in self?.viewModel.onEnter(reference: $0) }
        inputCell.onFetchText = { [weak self] in
            self?.viewModel.onEnter(reference: $0)
            self?.inputCell.inputText = $0
        }
        inputCell.onOpenViewController = { [weak self] in self?.present($0, animated: true) }

        inputCautionCell.onChangeHeight = { [weak self] in self?.reloadHeights() }

        view.addSubview(addButtonHolder)
        addButtonHolder.snp.makeConstraints { maker in
            maker.top.equalTo(tableView.snp.bottom).offset(-CGFloat.margin16)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        addButtonHolder.addSubview(addButton)
        addButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(CGFloat.margin24)
            maker.height.equalTo(CGFloat.heightButton)
        }

        addButton.apply(style: .primaryYellow)
        addButton.setTitle("button.add".localized, for: .normal)
        addButton.addTarget(self, action: #selector(onTapAddButton), for: .touchUpInside)

        subscribe(disposeBag, viewModel.loadingDriver) { [weak self] loading in
            self?.inputCell.set(isLoading: loading)
        }
        subscribe(disposeBag, viewModel.viewItemDriver) { [weak self] viewItem in
            self?.viewItem = viewItem
            self?.reloadTable()
        }
        subscribe(disposeBag, viewModel.buttonEnabledDriver) { [weak self] enabled in
            self?.addButton.isEnabled = enabled
        }
        subscribe(disposeBag, viewModel.cautionDriver) { [weak self] caution in
            self?.inputCell.set(cautionType: caution?.type)
            self?.inputCautionCell.set(caution: caution)
            self?.reloadHeights()
        }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in
            HudHelper.instance.showSuccess(title: "add_token.success_add".localized)
            self?.dismiss(animated: true)
        }

        tableView.buildSections()

        isLoaded = true
    }

    @objc private func onTapAddButton() {
        viewModel.onTapButton()
    }

    @objc private func onTapCancelButton() {
        dismiss(animated: true)
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

    private func reloadTable() {
        guard isLoaded else {
            return
        }

        tableView.reload(animated: true)
    }

}

extension AddTokenViewController: SectionsDataSource {

    private func header(text: String) -> ViewState<SubtitleHeaderFooterView> {
        .cellType(
                hash: text,
                binder: { $0.bind(text: text)},
                dynamicHeight: { _ in SubtitleHeaderFooterView.height }
        )
    }

    private func infoRow(id: String, title: String, value: String?, isFirst: Bool = false, isLast: Bool = false) -> RowProtocol {
        CellBuilder.row(
                elements: [.text, .text],
                tableView: tableView,
                id: id,
                hash: value,
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)

                    cell.bind(index: 0) { (component: TextComponent) in
                        component.set(style: .d1)
                        component.text = title
                    }

                    cell.bind(index: 1) { (component: TextComponent) in
                        component.set(style: .c2)
                        component.text = value ?? "---"
                    }
                }
        )
    }

    private func tokenRow(viewItem: AddTokenViewModel.TokenViewItem, index: Int, isFirst: Bool, isLast: Bool) -> RowProtocol {
        CellBuilder.row(
                elements: [.image24, .text, .switch],
                tableView: tableView,
                id: "token-\(index)",
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)

                    cell.bind(index: 0) { (component: ImageComponent) in
                        component.setImage(urlString: viewItem.imageUrl, placeholder: nil)
                    }

                    cell.bind(index: 1) { (component: TextComponent) in
                        component.set(style: .b2)
                        component.text = viewItem.title
                    }

                    cell.bind(index: 2) { (component: SwitchComponent) in
                        component.switchView.isEnabled = viewItem.enabled
                        component.switchView.isOn = viewItem.isOn
                        component.onSwitch = { [weak self] in
                            self?.viewModel.onToggleToken(index: index, isOn: $0)
                        }
                    }
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        var sections: [SectionProtocol] = [
            Section(
                    id: "input",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin12),
                    rows: [
                        StaticRow(
                                cell: inputCell,
                                id: "input",
                                dynamicHeight: { [weak self] width in
                                    self?.inputCell.height(containerWidth: width) ?? 0
                                }
                        ),
                        StaticRow(
                                cell: inputCautionCell,
                                id: "input-caution",
                                dynamicHeight: { [weak self] width in
                                    self?.inputCautionCell.height(containerWidth: width) ?? 0
                                }
                        )
                    ]
            ),

            Section(
                    id: "coin-info",
                    footerState: .margin(height: .margin32),
                    rows: [
                        infoRow(id: "coin-name", title: "add_token.coin_name".localized, value: viewItem?.coinName, isFirst: true),
                        infoRow(id: "coin-code", title: "add_token.coin_code".localized, value: viewItem?.coinCode),
                        infoRow(id: "decimals", title: "add_token.decimals".localized, value: viewItem?.decimals, isLast: true)
                    ]
            )
        ]

        if let tokenViewItems = viewItem?.tokenViewItems {
            let section = Section(
                    id: "tokens",
                    headerState: header(text: "add_token.coin_types".localized),
                    footerState: .margin(height: .margin32),
                    rows: tokenViewItems.enumerated().map { index, tokenViewItem in
                        tokenRow(
                                viewItem: tokenViewItem,
                                index: index,
                                isFirst: index == 0,
                                isLast: index == tokenViewItems.count - 1
                        )
                    }
            )

            sections.append(section)
        }

        return sections
    }

}
