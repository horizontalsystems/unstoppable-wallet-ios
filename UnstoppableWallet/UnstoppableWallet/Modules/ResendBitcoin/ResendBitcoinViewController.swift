import ComponentKit
import RxSwift
import SectionsTableView
import SnapKit
import ThemeKit
import UIKit

class ResendBitcoinViewController: KeyboardAwareViewController, SectionsDataSource {
    private let disposeBag = DisposeBag()
    private let viewModel: ResendBitcoinViewModel

    private let tableView = SectionsTableView(style: .grouped)
    private let bottomWrapper = BottomGradientHolder()
    private let minFeeCell: StepperAmountInputCell
    private let cautionCell = TitledHighlightedDescriptionCell()
    private let sendButton = SliderButton()

    private var viewItems = [[ResendBitcoinViewModel.ViewItem]]()
    private var loaded = false

    init(viewModel: ResendBitcoinViewModel) {
        self.viewModel = viewModel

        minFeeCell = StepperAmountInputCell(allowFractionalNumbers: false)
        super.init(scrollViews: [tableView], accessoryView: bottomWrapper)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.replaceType == .speedUp ? "send.confirmation.speed_up".localized : "send.confirmation.cancel".localized
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .done, target: self, action: #selector(onTapCancel))

        tableView.sectionDataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.delaysContentTouches = false
        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        bottomWrapper.add(to: self)
        bottomWrapper.addSubview(sendButton)

        sendButton.title = viewModel.replaceType == .speedUp ? "send.confirmation.slide_to_resend".localized : "send.confirmation.slide_to_cancel".localized
        sendButton.finalTitle = "send.confirmation.sending".localized
        sendButton.slideImage = UIImage(named: "arrow_medium_2_right_24")
        sendButton.finalImage = UIImage(named: "check_2_24")
        sendButton.onTap = { [weak self] in
            self?.viewModel.send()
        }

        subscribe(disposeBag, viewModel.sendEnabledDriver) { [weak self] in self?.sendButton.isEnabled = $0 }
        subscribe(disposeBag, viewModel.viewItemDriver) { [weak self] in self?.sync(viewItems: $0) }

        subscribe(disposeBag, viewModel.sendingSignal) { HudHelper.instance.show(banner: .sending) }
        subscribe(disposeBag, viewModel.sendSuccessSignal) { [weak self] in self?.handleSendSuccess() }
        subscribe(disposeBag, viewModel.sendFailedSignal) { [weak self] in self?.handleSendFailed(error: $0) }
        subscribe(disposeBag, viewModel.minFeeDriver) { [weak self] in self?.minFeeCell.value = $0 }
        subscribe(disposeBag, viewModel.cautionDriver) { [weak self] in self?.handle(caution: $0) }

        minFeeCell.onChangeValue = { [weak self] value in self?.viewModel.set(minFee: value) }

        handle(caution: nil)
        loaded = true
    }

    private func sync(viewItems: [[ResendBitcoinViewModel.ViewItem]]) {
        self.viewItems = viewItems
        tableView.reload()
    }

    @objc private func onTapCancel() {
        dismiss(animated: true)
    }

    func handleSendSuccess() {
        HudHelper.instance.show(banner: .sent)

        dismiss(animated: true)
    }

    private func handleSendFailed(error: String) {
        HudHelper.instance.show(banner: .error(string: error))
        sendButton.reset()
    }

    private func handle(caution: TitledCaution?) {
        cautionCell.isVisible = caution != nil

        if let caution {
            cautionCell.bind(caution: caution)
        }

        if loaded {
            UIView.animate(withDuration: 0.15) {
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }
        }
    }

    private func row(viewItem: ResendBitcoinViewModel.ViewItem, rowInfo: RowInfo) -> RowProtocol {
        switch viewItem {
        case let .amount(title, token, coinAmount, currencyAmount, type):
            return CellComponent.amountRow(tableView: tableView, rowInfo: rowInfo, title: title, subtitle: token.fullBadge, imageUrl: token.coin.imageUrl, placeholderImageName: token.placeholderImageName, coinAmount: coinAmount, currencyAmount: currencyAmount, type: type)
        case let .address(title, value, valueTitle, contactAddress, statSection):
            var onAddToContact: (() -> Void)? = nil
            if let contactAddress {
                onAddToContact = { [weak self] in
                    ContactBookModule.showAddition(contactAddress: contactAddress, parentViewController: self, statPage: .resend, statSection: statSection)
                }
            }
            return CellComponent.fromToRow(tableView: tableView, rowInfo: rowInfo, title: title, value: value, valueTitle: valueTitle, statPage: .resend, statSection: statSection, onAddToContact: onAddToContact)
        case let .value(iconName, title, value, type):
            return CellComponent.valueRow(tableView: tableView, rowInfo: rowInfo, iconName: iconName, title: title, value: value, type: type)
        case let .fee(title, coinValue, currencyValue):
            return CellComponent.doubleAmountRow(tableView: tableView, rowInfo: rowInfo, title: title, coinValue: coinValue, currencyValue: currencyValue)
        }
    }
}

extension ResendBitcoinViewController {
    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()
        for (index, viewItems) in viewItems.enumerated() {
            sections.append(
                Section(
                    id: "section-\(index)",
                    headerState: .margin(height: index == 0 ? .margin12 : .margin16),
                    rows: viewItems.enumerated().map { index, viewItem in
                        row(viewItem: viewItem, rowInfo: RowInfo(index: index, isFirst: index == 0, isLast: index == viewItems.count - 1))
                    }
                ))
        }

        sections.append(
            Section(
                id: "min-fee",
                headerState: .margin(height: .margin16),
                footerState: .margin(height: .margin16),
                rows: [
                    CellBuilderNew.row(
                        rootElement: .hStack([
                            .text { (component: TextComponent) in
                                component.font = .subhead1
                                component.textColor = .themeGray
                                component.text = "send.confirmation.fee".localized + " (Sat)"
                            },
                        ]),
                        layoutMargins: UIEdgeInsets(top: 0, left: .margin32, bottom: 0, right: .margin32),
                        tableView: tableView,
                        id: "min-fee-title",
                        height: .margin32,
                        autoDeselect: true,
                        bind: { cell in
                            cell.set(backgroundStyle: .transparent, isFirst: true)
                            cell.selectionStyle = .none
                        }
                    ),
                    StaticRow(
                        cell: minFeeCell,
                        id: "fee-rate-cell",
                        height: .heightCell48
                    ),
                ]
            )
        )

        let cautionsSections: [SectionProtocol] = [
            Section(
                id: "caution",
                rows: [
                    StaticRow(
                        cell: cautionCell,
                        id: "caution",
                        dynamicHeight: { [weak self] containerWidth in
                            self?.cautionCell.cellHeight(containerWidth: containerWidth) ?? 0
                        }
                    ),
                ]
            ),
        ]

        return sections + cautionsSections
    }
}
