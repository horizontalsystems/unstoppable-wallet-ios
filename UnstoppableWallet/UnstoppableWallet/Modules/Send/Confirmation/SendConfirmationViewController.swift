import UIKit
import SnapKit
import SectionsTableView
import RxSwift
import ThemeKit
import ComponentKit

class SendConfirmationViewController: ThemeViewController, SectionsDataSource {
    private let disposeBag = DisposeBag()
    private let viewModel: SendConfirmationViewModel

    private let tableView = SectionsTableView(style: .grouped)
    private let bottomWrapper = BottomGradientHolder()
    private let sendButton = SliderButton()

    private var viewItems = [[SendConfirmationViewModel.ViewItem]]()

    init(viewModel: SendConfirmationViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "confirm".localized

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .done, target: self, action: #selector(onTapCancel))

        tableView.sectionDataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.delaysContentTouches = false
        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        bottomWrapper.add(to: self, under: tableView)
        bottomWrapper.addSubview(sendButton)

        sendButton.title = "send.confirmation.slide_to_send".localized
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

    }

    private func sync(viewItems: [[SendConfirmationViewModel.ViewItem]]) {
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

    private func row(viewItem: SendConfirmationViewModel.ViewItem, rowInfo: RowInfo) -> RowProtocol {
        switch viewItem {
        case let .subhead(iconName, title, value):
            return CellComponent.actionTitleRow(tableView: tableView, rowInfo: rowInfo, iconName: iconName, iconDimmed: true, title: title, value: value)
        case let .amount(iconUrl, iconPlaceholderImageName, coinAmount, currencyAmount, type):
            return CellComponent.amountRow(tableView: tableView, rowInfo: rowInfo, iconUrl: iconUrl, iconPlaceholderImageName: iconPlaceholderImageName, coinAmount: coinAmount, currencyAmount: currencyAmount, type: type)
        case let .address(title, value, valueTitle, contactAddress):
            var onAddToContact: (() -> ())? = nil
            if let contactAddress {
                onAddToContact = { [weak self] in
                    ContactBookModule.showAddition(contactAddress: contactAddress, parentViewController: self)
                }
            }
            return CellComponent.fromToRow(tableView: tableView, rowInfo: rowInfo, title: title, value: value, valueTitle: valueTitle, onAddToContact: onAddToContact)
        case let .value(iconName, title, value, type):
            return CellComponent.valueRow(tableView: tableView, rowInfo: rowInfo, iconName: iconName, title: title, value: value, type: type)
        }
    }

}

extension SendConfirmationViewController {

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()
        viewItems.enumerated().forEach { index, viewItems in
            sections.append(
                    Section(
                            id: "section-\(index)",
                            headerState: .margin(height: .margin12),
                            rows: viewItems.enumerated().map { index, viewItem in
                                row(viewItem: viewItem, rowInfo: RowInfo(index: index, isFirst: index == 0, isLast: index == viewItems.count - 1))
                            }))
        }

        return sections
    }

}
