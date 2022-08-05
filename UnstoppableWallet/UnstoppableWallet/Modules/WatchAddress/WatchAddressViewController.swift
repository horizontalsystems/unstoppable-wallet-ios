import UIKit
import ThemeKit
import SnapKit
import SectionsTableView
import ComponentKit
import RxSwift
import RxCocoa
import UIExtensions

class WatchAddressViewController: KeyboardAwareViewController {
    private let wrapperViewHeight: CGFloat = .heightButton + .margin16 + .margin16
    private let viewModel: WatchAddressViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private let gradientWrapperView = GradientView(gradientHeight: .margin16, fromColor: UIColor.themeTyler.withAlphaComponent(0), toColor: UIColor.themeTyler)
    private let watchButton = PrimaryButton()

    private let addressCell: RecipientAddressInputCell
    private let addressCautionCell: RecipientAddressCautionCell

    private let nameCell = TextFieldCell()

    private var isLoaded = false

    init(viewModel: WatchAddressViewModel, addressViewModel: RecipientAddressViewModel) {
        self.viewModel = viewModel

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
            maker.top.equalToSuperview().inset(CGFloat.margin16)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide)
        }

        watchButton.set(style: .yellow)
        watchButton.setTitle("watch_address.watch".localized, for: .normal)
        watchButton.addTarget(self, action: #selector(onTapWatch), for: .touchUpInside)

        addressCell.onChangeHeight = { [weak self] in self?.reloadTable() }
        addressCell.onOpenViewController = { [weak self] in self?.present($0, animated: true) }

        addressCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }

        nameCell.inputPlaceholder = viewModel.namePlaceholder
        nameCell.onChangeText = { [weak self] in self?.viewModel.onChange(name: $0) }

        subscribe(disposeBag, viewModel.nameDriver) { [weak self] name in
            self?.nameCell.inputText = name
        }
        subscribe(disposeBag, viewModel.watchEnabledDriver) { [weak self] enabled in
            self?.navigationItem.rightBarButtonItem?.isEnabled = enabled
            self?.watchButton.isEnabled = enabled
        }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in
            self?.dismiss(animated: true)
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

}

extension WatchAddressViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(id: "top-margin", headerState: .margin(height: .margin12)),
            Section(
                    id: "address",
                    headerState: tableView.sectionHeader(text: "watch_address.address".localized),
                    footerState: tableView.sectionFooter(text: "watch_address.description".localized),
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
            ),
            Section(
                    id: "name",
                    headerState: tableView.sectionHeader(text: "watch_address.name".localized),
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: nameCell,
                                id: "name",
                                height: .heightSingleLineCell
                        )
                    ]
            ),
        ]
    }

}
