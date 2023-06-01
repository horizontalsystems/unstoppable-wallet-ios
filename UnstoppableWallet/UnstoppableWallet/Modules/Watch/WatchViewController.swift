import UIKit
import ThemeKit
import SnapKit
import SectionsTableView
import ComponentKit
import RxSwift
import RxCocoa
import UIExtensions

class WatchViewController: KeyboardAwareViewController {
    private let wrapperViewHeight: CGFloat = .heightButton + .margin32 + .margin16
    private let viewModel: WatchViewModel
    private let publicKeyViewModel: WatchPublicKeyViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private let gradientWrapperView = GradientView(gradientHeight: .margin16, fromColor: UIColor.themeTyler.withAlphaComponent(0), toColor: UIColor.themeTyler)
    private let nextButton = PrimaryButton()

    private let nameCell = TextFieldCell()
    private let addressCell: RecipientAddressInputCell
    private let addressCautionCell: RecipientAddressCautionCell

    private let publicKeyInputCell = TextInputCell()
    private let publicKeyCautionCell = FormCautionCell()

    private var watchType: WatchModule.WatchType = .evmAddress
    private var isLoaded = false

    private weak var sourceViewController: UIViewController?

    init(viewModel: WatchViewModel, addressViewModel: RecipientAddressViewModel, publicKeyViewModel: WatchPublicKeyViewModel, sourceViewController: UIViewController?) {
        self.viewModel = viewModel
        self.publicKeyViewModel = publicKeyViewModel
        self.sourceViewController = sourceViewController

        addressCell = RecipientAddressInputCell(viewModel: addressViewModel)
        addressCautionCell = RecipientAddressCautionCell(viewModel: addressViewModel)

        super.init(scrollViews: [tableView], accessoryView: gradientWrapperView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "watch_address.title".localized

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.next".localized, style: .done, target: self, action: #selector(onTapNext))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionDataSource = self

        view.addSubview(gradientWrapperView)
        gradientWrapperView.snp.makeConstraints { maker in
            maker.height.equalTo(wrapperViewHeight).priority(.high)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        gradientWrapperView.addSubview(nextButton)
        nextButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin32)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).inset(CGFloat.margin16)
        }

        nextButton.set(style: .yellow)
        nextButton.setTitle("button.next".localized, for: .normal)
        nextButton.addTarget(self, action: #selector(onTapNext), for: .touchUpInside)

        let defaultName = viewModel.defaultName
        nameCell.inputText = defaultName
        nameCell.inputPlaceholder = defaultName
        nameCell.autocapitalizationType = .words
        nameCell.onChangeText = { [weak self] in self?.viewModel.onChange(name: $0 ?? "") }

        addressCell.onChangeHeight = { [weak self] in self?.reloadTable() }
        addressCell.onOpenViewController = { [weak self] in self?.present($0, animated: true) }

        addressCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }

        publicKeyInputCell.set(placeholderText: "watch_address.public_key.placeholder".localized)
        publicKeyInputCell.onChangeHeight = { [weak self] in self?.reloadTable() }
        publicKeyInputCell.onChangeText = { [weak self] in self?.publicKeyViewModel.onChange(text: $0) }
        publicKeyInputCell.onChangeTextViewCaret = { [weak self] in self?.syncContentOffsetIfRequired(textView: $0) }
        publicKeyInputCell.onOpenViewController = { [weak self] in self?.present($0, animated: true) }

        publicKeyCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }

        subscribe(disposeBag, viewModel.nameSignal) { [weak self] name in
            self?.nameCell.inputText = name
            self?.nameCell.inputPlaceholder = name
        }
        subscribe(disposeBag, viewModel.watchTypeDriver) { [weak self] watchType in
            self?.watchType = watchType
            self?.tableView.reload()
        }
        subscribe(disposeBag, publicKeyViewModel.cautionDriver) { [weak self] caution in
            self?.publicKeyInputCell.set(cautionType: caution?.type)
            self?.publicKeyCautionCell.set(caution: caution)
        }
        subscribe(disposeBag, viewModel.watchEnabledDriver) { [weak self] enabled in
            self?.navigationItem.rightBarButtonItem?.isEnabled = enabled
            self?.nextButton.isEnabled = enabled
        }
        subscribe(disposeBag, viewModel.proceedSignal) { [weak self] (watchType, accountType, name) in
            self?.proceedToNextPage(watchType: watchType, accountType: accountType, name: name)
        }

        additionalContentInsets = UIEdgeInsets(top: 0, left: 0, bottom: -.margin16, right: 0)
        additionalInsetsOnlyForClosedKeyboard = false
        ignoreSafeAreaForAccessoryView = false

        tableView.buildSections()
        isLoaded = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        setInitialState(bottomPadding: gradientWrapperView.height)
    }

    @objc private func onTapNext() {
        viewModel.onTapNext()
    }

    private func reloadTable() {
        guard isLoaded else {
            return
        }

        tableView.buildSections()
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    private func onTapWatchType() {
        let alertController = AlertRouter.module(
                title: "watch_address.watch_by".localized,
                viewItems: WatchModule.WatchType.allCases.enumerated().map { index, watchType in
                    AlertViewItem(
                            text: watchType.title,
                            selected: self.watchType == watchType
                    )
                }
        ) { [weak self] index in
            self?.viewModel.onSelect(watchType: WatchModule.WatchType.allCases[index])
        }

        present(alertController, animated: true)
    }

    private func proceedToNextPage(watchType: WatchModule.WatchType, accountType: AccountType, name: String) {
        let viewController = WatchModule.viewController(sourceViewController: sourceViewController, watchType: watchType, accountType: accountType, name: name)

        navigationController?.pushViewController(viewController, animated: true)
    }

}

extension WatchViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections: [SectionProtocol] = [
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

        sections.append(
                Section(
                        id: "watch-type",
                        footerState: .margin(height: .margin32),
                        rows: [
                            tableView.universalRow48(
                                    id: "watch_type",
                                    title: .body("watch_address.by".localized),
                                    value: .subhead1(watchType.title, color: .themeGray),
                                    accessoryType: .dropdown,
                                    autoDeselect: true,
                                    isFirst: true,
                                    isLast: true
                            ) { [weak self] in
                                self?.onTapWatchType()
                            }
                        ]
                )
        )

        switch watchType {
        case .evmAddress:
            let evmAddressSection: SectionProtocol = Section(
                    id: "address",
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: addressCell,
                                id: "address-input",
                                dynamicHeight: { [weak self] width in
                                    self?.addressCell.height(containerWidth: width) ?? 0
                                }
                        ),
                        StaticRow(
                                cell: addressCautionCell,
                                id: "address-caution",
                                dynamicHeight: { [weak self] width in
                                    self?.addressCautionCell.height(containerWidth: width) ?? 0
                                }
                        )
                    ]
            )

            sections.append(evmAddressSection)
        case .tronAddress:
            let tronAddressSection: SectionProtocol = Section(
                    id: "address",
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: addressCell,
                                id: "address-input",
                                dynamicHeight: { [weak self] width in
                                    self?.addressCell.height(containerWidth: width) ?? 0
                                }
                        ),
                        StaticRow(
                                cell: addressCautionCell,
                                id: "address-caution",
                                dynamicHeight: { [weak self] width in
                                    self?.addressCautionCell.height(containerWidth: width) ?? 0
                                }
                        )
                    ]
            )

            sections.append(tronAddressSection)
        case .publicKey:
            let publicKeySection: SectionProtocol = Section(
                    id: "public-key-input",
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: publicKeyInputCell,
                                id: "public-key-input",
                                dynamicHeight: { [weak self] width in
                                    self?.publicKeyInputCell.cellHeight(containerWidth: width) ?? 0
                                }
                        ),
                        StaticRow(
                                cell: publicKeyCautionCell,
                                id: "public-key-caution",
                                dynamicHeight: { [weak self] width in
                                    self?.publicKeyCautionCell.height(containerWidth: width) ?? 0
                                }
                        )
                    ]
            )

            sections.append(publicKeySection)
        }

        return sections
    }

}
