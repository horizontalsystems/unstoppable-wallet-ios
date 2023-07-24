import UIKit
import RxSwift
import RxCocoa
import SnapKit
import ThemeKit
import ComponentKit
import SectionsTableView
import UIExtensions

class CreateAccountSimpleViewController: KeyboardAwareViewController {
    private let viewModel: CreateAccountViewModel
    private let disposeBag = DisposeBag()
    private weak var listener: ICreateAccountListener?

    private let tableView = SectionsTableView(style: .grouped)
    private let nameCell = TextFieldCell()

    private let gradientWrapperView = BottomGradientHolder()
    private let createButton = PrimaryButton()

    private var isLoaded = false

    init(viewModel: CreateAccountViewModel, listener: ICreateAccountListener?) {
        self.viewModel = viewModel
        self.listener = listener

        super.init(scrollViews: [tableView])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "create_wallet.title".localized
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "create_wallet.create".localized, style: .done, target: self, action: #selector(onTapCreate))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.largeTitleDisplayMode = .never

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self

        gradientWrapperView.add(to: self)

        gradientWrapperView.addSubview(createButton)

        createButton.set(style: .yellow)
        createButton.setTitle("create_wallet.create".localized, for: .normal)
        createButton.addTarget(self, action: #selector(onTapCreate), for: .touchUpInside)

        let advancedButton = PrimaryButton()

        gradientWrapperView.addSubview(advancedButton)

        advancedButton.set(style: .transparent)
        advancedButton.setTitle("create_wallet.advanced".localized, for: .normal)
        advancedButton.addTarget(self, action: #selector(onTapAdvanced), for: .touchUpInside)

        let namePlaceholder = viewModel.namePlaceholder
        nameCell.inputText = namePlaceholder
        nameCell.inputPlaceholder = namePlaceholder
        nameCell.autocapitalizationType = .words
        nameCell.onChangeText = { [weak self] in self?.viewModel.onChange(name: $0 ?? "") }

        subscribe(disposeBag, viewModel.showErrorSignal) { [weak self] in self?.show(error: $0) }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in self?.finish() }

        tableView.buildSections()
        isLoaded = true
    }

    @objc private func onTapCancel() {
        dismiss(animated: true)
    }

    @objc private func onTapCreate() {
        viewModel.onTapCreate()
    }

    @objc private func onTapAdvanced() {
        let module = CreateAccountModule.viewController(advanced: true, listener: listener)
        navigationController?.pushViewController(module, animated: true)
    }

    private func show(error: String) {
        HudHelper.instance.show(banner: .error(string: error))
    }

    private func finish() {
        HudHelper.instance.show(banner: .created)

        if let listener = listener {
            listener.handleCreateAccount()
        } else {
            dismiss(animated: true)
        }
    }

}

extension CreateAccountSimpleViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "margin",
                    headerState: .margin(height: .margin12)
            ),
            Section(
                    id: "name",
                    headerState: tableView.sectionHeader(text: "create_wallet.name".localized),
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: nameCell,
                                id: "name",
                                height: .heightSingleLineCell
                        )
                    ]
            )
        ]
    }

}
