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
    private let watchButton = PrimaryButton()

    private let addressCell: RecipientAddressInputCell
    private let addressCautionCell: RecipientAddressCautionCell

    private let publicKeyInputCell = TextInputCell()
    private let publicKeyCautionCell = FormCautionCell()

    private var watchType: WatchViewModel.WatchType = .evmAddress
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
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "watch_address.watch".localized, style: .done, target: self, action: #selector(onTapWatch))

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

        gradientWrapperView.addSubview(watchButton)
        watchButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin32)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).inset(CGFloat.margin16)
        }

        watchButton.set(style: .yellow)
        watchButton.setTitle("watch_address.watch".localized, for: .normal)
        watchButton.addTarget(self, action: #selector(onTapWatch), for: .touchUpInside)

        addressCell.onChangeHeight = { [weak self] in self?.reloadTable() }
        addressCell.onOpenViewController = { [weak self] in self?.present($0, animated: true) }

        addressCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }

        publicKeyInputCell.set(placeholderText: "watch_address.public_key.placeholder".localized)
        publicKeyInputCell.onChangeHeight = { [weak self] in self?.reloadTable() }
        publicKeyInputCell.onChangeText = { [weak self] in self?.publicKeyViewModel.onChange(text: $0) }
        publicKeyInputCell.onChangeTextViewCaret = { [weak self] in self?.syncContentOffsetIfRequired(textView: $0) }
        publicKeyInputCell.onOpenViewController = { [weak self] in self?.present($0, animated: true) }

        publicKeyCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }

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
            self?.watchButton.isEnabled = enabled
        }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in
            HudHelper.instance.show(banner: .addressAdded)
            (self?.sourceViewController ?? self)?.dismiss(animated: true)
        }

        setInitialState(bottomPadding: wrapperViewHeight)

        tableView.buildSections()
        isLoaded = true
    }

    @objc private func onTapCancel() {
        dismiss(animated: true)
    }

    @objc private func onTapWatch() {
        viewModel.onTapWatch()
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
                viewItems: WatchViewModel.WatchType.allCases.enumerated().map { index, watchType in
                    AlertViewItem(
                            text: watchType.title,
                            selected: self.watchType == watchType
                    )
                }
        ) { [weak self] index in
            self?.viewModel.onSelect(watchType: WatchViewModel.WatchType.allCases[index])
        }

        present(alertController, animated: true)
    }

}

extension WatchViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        sections.append(
                Section(
                        id: "watch-type",
                        headerState: .margin(height: .margin12),
                        footerState: .margin(height: .margin32),
                        rows: [
                            CellBuilderNew.row(
                                    rootElement: .hStack([
                                        .text { component in
                                            component.font = .body
                                            component.textColor = .themeLeah
                                            component.text = "watch_address.by".localized
                                        },
                                        .text { [weak self] component in
                                            component.font = .subhead1
                                            component.textColor = .gray
                                            component.text = self?.watchType.title
                                        },
                                        .image20 { component in
                                            component.imageView.image = UIImage(named: "arrow_small_down_20")?.withTintColor(.themeGray)
                                        }
                                    ]),
                                    tableView: tableView,
                                    id: "watch_type",
                                    autoDeselect: true,
                                    bind: { cell in
                                        cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
                                    },
                                    action: { [weak self] in
                                        self?.onTapWatchType()
                                    }
                            )
                        ]
                )
        )

        switch watchType {
        case .evmAddress:
            let evmAddressSection: SectionProtocol = Section(
                    id: "address",
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
        case .publicKey:
            let publicKeySection: SectionProtocol = Section(
                    id: "public-key-input",
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
