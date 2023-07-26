import Combine
import UIKit
import SnapKit
import ThemeKit
import ComponentKit
import SectionsTableView
import HUD

class CexDepositViewController: ThemeViewController {
    private let viewModel: CexDepositViewModel
    private var cancellables = Set<AnyCancellable>()

    private let tableView = SectionsTableView(style: .grouped)
    private let spinner = HUDActivityView.create(with: .medium24)
    private let failedView = PlaceholderView()
    private let buttonsHolder = BottomGradientHolder()

    private var viewItem: CexDepositViewModel.ViewItem?
    private var memoWarningShown = false

    init(viewModel: CexDepositViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "cex_deposit.title".localized(viewModel.coinCode)

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .done, target: self, action: #selector(onTapDone))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
        }

        tableView.sectionDataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.registerCell(forClass: QrCodeCell.self)

        view.addSubview(spinner)
        spinner.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        spinner.startAnimating()

        view.addSubview(failedView)
        failedView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        failedView.image = UIImage(named: "sync_error_48")
        failedView.text = "cex_deposit.failed".localized
        failedView.addPrimaryButton(
                style: .yellow,
                title: "button.retry".localized,
                target: self,
                action: #selector(onTapRetry)
        )

        buttonsHolder.add(to: self, under: tableView)
        let copyButton = PrimaryButton()
        buttonsHolder.addSubview(copyButton)

        copyButton.set(style: .yellow)
        copyButton.setTitle("cex_deposit.copy_address".localized, for: .normal)
        copyButton.addTarget(self, action: #selector(onTapCopy), for: .touchUpInside)

        let shareButton = PrimaryButton()
        buttonsHolder.addSubview(shareButton)

        shareButton.set(style: .gray)
        shareButton.setTitle("cex_deposit.share_address".localized, for: .normal)
        shareButton.addTarget(self, action: #selector(onTapShare), for: .touchUpInside)

        viewModel.$spinnerVisible
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.spinner.isHidden = !$0 }
                .store(in: &cancellables)

        viewModel.$errorVisible
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.failedView.isHidden = !$0 }
                .store(in: &cancellables)

        viewModel.$viewItem
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.sync(viewItem: $0) }
                .store(in: &cancellables)
    }

    private func sync(viewItem: CexDepositViewModel.ViewItem?) {
        self.viewItem = viewItem
        tableView.isHidden = viewItem == nil
        buttonsHolder.isHidden = viewItem == nil
        tableView.reload()

        if let viewItem, viewItem.memo != nil, !memoWarningShown {
            showMemoWarning()
            memoWarningShown = true
        }
    }

    @objc private func onTapDone() {
        dismiss(animated: true)
    }

    @objc private func onTapRetry() {
        viewModel.onTapRetry()
    }

    @objc private func onTapCopy() {
        guard let address = viewItem?.address else {
            return
        }

        CopyHelper.copyAndNotify(value: address)
    }

    @objc private func onTapShare() {
        guard let address = viewItem?.address else {
            return
        }

        let activityViewController = UIActivityViewController(activityItems: [address], applicationActivities: [])
        present(activityViewController, animated: true, completion: nil)
    }

    private func showMemoWarning() {
        let viewController = BottomSheetModule.viewController(
                image: .local(image: UIImage(named: "warning_2_24")?.withTintColor(.themeLucian)),
                title: "cex_deposit.memo_warning.title".localized,
                items: [
                    .highlightedDescription(text: "cex_deposit.memo_warning.description".localized, style: .red)
                ],
                buttons: [
                    .init(style: .yellow, title: "button.i_understand".localized)
                ]
        )

        present(viewController, animated: true)
    }

}

extension CexDepositViewController: SectionsDataSource {

    private func addressRow(value: String, isLast: Bool) -> RowProtocol {
        let backgroundStyle: BaseThemeCell.BackgroundStyle = .lawrence
        let title = "cex_deposit.address".localized
        let titleFont: UIFont = .subhead2
        let valueFont: UIFont = .subhead1

        return CellBuilderNew.row(
                rootElement: .hStack([
                    .textElement(text: .subhead2(title)),
                    .text { component in
                        component.textAlignment = .right
                        component.font = valueFont
                        component.textColor = .themeLeah
                        component.text = value
                        component.numberOfLines = 0
                    }
                ]),
                tableView: tableView,
                id: "address",
                dynamicHeight: { containerWidth in
                    CellBuilderNew.height(
                            containerWidth: containerWidth,
                            backgroundStyle: backgroundStyle,
                            text: value,
                            font: valueFont,
                            elements: [
                                .fixed(width: TextComponent.width(font: titleFont, text: title)),
                                .multiline
                            ]
                    )
                },
                bind: { cell in
                    cell.set(backgroundStyle: backgroundStyle, isFirst: true, isLast: isLast)
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        guard let viewItem else {
            return []
        }

        let qrCodeText = "cex_deposit.qr_code_description".localized(viewModel.coinCode)

        let networkName = viewModel.networkName
        let memo = viewItem.memo
        let minAmount = viewModel.minAmount

        let items: [Any?] = [true, networkName, memo, minAmount]
        let itemCount = items.compactMap { $0 }.count

        var mainRows: [RowProtocol] = [
            addressRow(value: viewItem.address, isLast: itemCount == 1)
        ]

        if let networkName {
            mainRows.append(
                    tableView.universalRow48(
                            id: "network",
                            title: .subhead2("cex_deposit.network".localized),
                            value: .subhead1(networkName),
                            isLast: itemCount == mainRows.count + 1
                    )
            )
        }

        if let memo {
            mainRows.append(
                    CellBuilderNew.row(
                            rootElement: .hStack([
                                .textElement(text: .subhead2("cex_deposit.memo".localized)),
                                .textElement(text: .subhead1(memo)),
                                .secondaryCircleButton { component in
                                    component.button.set(image: UIImage(named: "copy_20"))
                                    component.onTap = {
                                        CopyHelper.copyAndNotify(value: memo)
                                    }
                                }
                            ]),
                            tableView: tableView,
                            id: "memo",
                            height: .heightCell48,
                            bind: { cell in
                                cell.set(backgroundStyle: .lawrence, isLast: itemCount == mainRows.count + 1)
                            }
                    )
            )
        }

        if let minAmount {
            mainRows.append(
                    tableView.universalRow48(
                            id: "min-amount",
                            title: .subhead2("cex_deposit.min_amount".localized),
                            value: .subhead1(minAmount),
                            isLast: itemCount == mainRows.count + 1
                    )
            )
        }

        return [
            Section(
                    id: "qr-code",
                    headerState: .margin(height: .margin12),
                    rows: [
                        Row<QrCodeCell>(
                                id: "qr-code",
                                dynamicHeight: { width in
                                    QrCodeCell.height(containerWidth: width, text: qrCodeText)
                                },
                                bind: { [weak self] cell, _ in
                                    cell.set(qrCodeString: viewItem.address, text: qrCodeText)
                                    cell.onTap = { self?.onTapCopy() }
                                }
                        )
                    ]
            ),
            Section(
                    id: "main",
                    headerState: .margin(height: .margin12),
                    rows: mainRows
            ),
            Section(
                    id: "description",
                    headerState: .margin(height: .margin4),
                    footerState: .margin(height: .margin32),
                    rows: [
                        tableView.highlightedDescriptionRow(
                                id: "warning",
                                style: viewItem.memo == nil ? .yellow : .red,
                                text: (viewItem.memo == nil ? "" : "\("cex_deposit.warning_memo".localized)\n\n") + "cex_deposit.warning".localized(viewModel.coinCode),
                                ignoreBottomMargin: true
                        )
                    ]
            )
        ]
    }

}
