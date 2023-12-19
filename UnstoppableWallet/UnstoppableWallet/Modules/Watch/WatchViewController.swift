import Combine
import ComponentKit
import HsExtensions
import SectionsTableView
import SnapKit
import ThemeKit
import UIExtensions
import UIKit

class WatchViewController: KeyboardAwareViewController {
    private let viewModel: WatchViewModel
    private var cancellables = Set<AnyCancellable>()

    private let tableView = SectionsTableView(style: .grouped)

    private let gradientWrapperView = BottomGradientHolder()
    private let nextButton = PrimaryButton()

    private let nameCell = TextFieldCell()

    private let watchDataInputCell = TextInputCell()
    private let watchDataCautionCell = FormCautionCell()

    private var isLoaded = false

    private weak var sourceViewController: UIViewController?

    init(viewModel: WatchViewModel, sourceViewController: UIViewController?) {
        self.viewModel = viewModel
        self.sourceViewController = sourceViewController

        super.init(scrollViews: [tableView], accessoryView: gradientWrapperView)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "watch_address.title".localized

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapClose))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "watch_address.watch".localized, style: .done, target: self, action: #selector(onTapNext))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionDataSource = self

        gradientWrapperView.add(to: self)
        gradientWrapperView.addSubview(nextButton)

        nextButton.set(style: .yellow)
        nextButton.setTitle("watch_address.watch".localized, for: .normal)
        nextButton.addTarget(self, action: #selector(onTapNext), for: .touchUpInside)

        let defaultName = viewModel.defaultName
        nameCell.inputText = defaultName
        nameCell.inputPlaceholder = defaultName
        nameCell.autocapitalizationType = .words
        nameCell.onChangeText = { [weak self] in self?.viewModel.onChange(name: $0 ?? "") }

        watchDataInputCell.set(placeholderText: "watch_address.watch_data.placeholder".localized)
        watchDataInputCell.onChangeHeight = { [weak self] in self?.reloadTable() }
        watchDataInputCell.onChangeText = { [weak self] in self?.viewModel.onChange(text: $0) }
        watchDataInputCell.onChangeTextViewCaret = { [weak self] in self?.syncContentOffsetIfRequired(textView: $0) }
        watchDataInputCell.onOpenViewController = { [weak self] in self?.present($0, animated: true) }

        watchDataCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }

        subscribe(&cancellables, viewModel.$name) { [weak self] name in
            self?.nameCell.inputText = name
            self?.nameCell.inputPlaceholder = name
        }
        subscribe(&cancellables, viewModel.$caution) { [weak self] caution in
            self?.watchDataInputCell.set(cautionType: caution?.type)
            self?.watchDataCautionCell.set(caution: caution)
        }
        subscribe(&cancellables, viewModel.$watchEnabled) { [weak self] enabled in
            self?.handleButtonState(enabled: enabled)
        }
        subscribe(&cancellables, viewModel.proceedPublisher) { [weak self] accountType, name in
            self?.proceedToNextPage(accountType: accountType, name: name)
        }

        tableView.buildSections()
        isLoaded = true
        handleButtonState(enabled: viewModel.watchEnabled)
    }

    @objc private func onTapNext() {
        viewModel.onTapNext()
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

    private func reloadTable() {
        guard isLoaded else {
            return
        }

        tableView.buildSections()
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    private func handleButtonState(enabled: Bool) {
        navigationItem.rightBarButtonItem?.isEnabled = enabled
        nextButton.isEnabled = enabled
    }

    private func proceedToNextPage(accountType: AccountType, name: String) {
        guard let viewController = WatchModule.viewController(sourceViewController: sourceViewController, accountType: accountType, name: name) else {
            WatchModule.watch(accountType: accountType, name: name)
            HudHelper.instance.show(banner: .walletAdded)
            (sourceViewController ?? self)?.dismiss(animated: true)
            return
        }

        navigationController?.pushViewController(viewController, animated: true)
    }
}

extension WatchViewController: SectionsDataSource {
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
                    ),
                ]
            ),
            Section(
                id: "watch-data-input",
                footerState: .margin(height: .margin32),
                rows: [
                    StaticRow(
                        cell: watchDataInputCell,
                        id: "watch-data-input",
                        dynamicHeight: { [weak self] width in
                            self?.watchDataInputCell.cellHeight(containerWidth: width) ?? 0
                        }
                    ),
                    StaticRow(
                        cell: watchDataCautionCell,
                        id: "watch-data-caution",
                        dynamicHeight: { [weak self] width in
                            self?.watchDataCautionCell.height(containerWidth: width) ?? 0
                        }
                    ),
                ]
            ),
        ]
    }
}
