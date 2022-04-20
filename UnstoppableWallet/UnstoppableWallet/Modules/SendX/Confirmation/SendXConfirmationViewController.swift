import UIKit
import SnapKit
import SectionsTableView
import RxSwift
import ThemeKit
import ComponentKit

class SendXConfirmationViewController: ThemeViewController, SectionsDataSource {
    private let disposeBag = DisposeBag()
    private let viewModel: SendXConfirmationViewModel

    private let tableView = SectionsTableView(style: .grouped)
    private let bottomWrapper = BottomGradientHolder()
    private let sendButton = ThemeButton()

    private var viewItems = [[SendXConfirmationViewModel.ViewItem]]()

    init(viewModel: SendXConfirmationViewModel) {
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

        view.addSubview(bottomWrapper)
        bottomWrapper.snp.makeConstraints { maker in
            maker.top.equalTo(tableView.snp.bottom).offset(-CGFloat.margin16)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        bottomWrapper.addSubview(sendButton)
        sendButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin32)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.bottom.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(CGFloat.heightButton)
        }

        sendButton.apply(style: .primaryYellow)
        sendButton.setTitle("send.confirmation.send_button".localized, for: .normal)
        sendButton.addTarget(self, action: #selector(onTapSend), for: .touchUpInside)

        subscribe(disposeBag, viewModel.sendEnabledDriver) { [weak self] in self?.sendButton.isEnabled = $0 }
        subscribe(disposeBag, viewModel.viewItemDriver) { [weak self] in self?.sync(viewItems: $0) }

        subscribe(disposeBag, viewModel.sendingSignal) { HudHelper.instance.showSpinner() }
        subscribe(disposeBag, viewModel.sendSuccessSignal) { [weak self] in self?.handleSendSuccess() }
        subscribe(disposeBag, viewModel.sendFailedSignal) { [weak self] in self?.handleSendFailed(error: $0) }

    }

    private func sync(viewItems: [[SendXConfirmationViewModel.ViewItem]]) {
        self.viewItems = viewItems
        tableView.reload()
    }

    @objc private func onTapCancel() {
        dismiss(animated: true)
    }

    @objc private func onTapSend() {
        viewModel.send()
    }

    func handleSendSuccess() {
        HudHelper.instance.showSuccess(title: "alert.success_action".localized)

        dismiss(animated: true)
    }

    private func handleSendFailed(error: String) {
        HudHelper.instance.showError(title: error)
    }

    private func textRow(primary: String, primaryStyle: TextComponent.Style, secondary: String?, secondaryStyle: TextComponent.Style?, index: Int, count: Int) -> RowProtocol {
        CellBuilder.row(
                elements: secondaryStyle != nil ? [.text, .text] : [.text],
                tableView: tableView,
                id: "text-row-\(index)-\(count)",
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: index == 0, isLast: index == count - 1)

                    cell.bind(index: 0) { (component: TextComponent) in
                        component.set(style: primaryStyle)
                        component.text = primary
                    }

                    if let secondaryStyle = secondaryStyle {
                        cell.bind(index: 1) { (component: TextComponent) in
                            component.set(style: secondaryStyle)
                            component.text = secondary
                        }
                    }
                }
        )
    }

    private func textButtonRow(primary: String, primaryStyle: TextComponent.Style, buttonText: String, buttonCopyValue: String, index: Int, count: Int) -> RowProtocol {
        CellBuilder.row(
                elements: [.text, .secondaryButton],
                tableView: tableView,
                id: "text-row-\(index)-\(count)",
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: index == 0, isLast: index == count - 1)

                    cell.bind(index: 0) { (component: TextComponent) in
                        component.set(style: primaryStyle)
                        component.text = primary
                        component.setContentCompressionResistancePriority(.required, for: .horizontal)
                    }

                    cell.bind(index: 1, block: { (component: SecondaryButtonComponent) in
                        component.button.set(style: .default)
                        component.button.setTitle(buttonText, for: .normal)
                        component.button.setContentHuggingPriority(.required, for: .horizontal)
                        component.button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                        component.onTap = {
                            CopyHelper.copyAndNotify(value: buttonCopyValue)
                        }
                    })
                }
        )
    }

    private func row(viewItem: SendXConfirmationViewModel.ViewItem, index: Int, count: Int) -> RowProtocol {
        switch viewItem {
        case .header(let title,let subtitle):
            return textRow(primary: title, primaryStyle: .b2, secondary: subtitle, secondaryStyle: .c1, index: index, count: count)
        case .amount(let primary, let secondary):
            return textRow(primary: primary, primaryStyle: .d1, secondary: secondary, secondaryStyle: .c3, index: index, count: count)
        case .recipient(let title, let address, let copyValue):
            return textButtonRow(primary: title, primaryStyle: .d1, buttonText: address, buttonCopyValue: copyValue, index: index, count: count)
        case .additional(let title, let value):
            return textRow(primary: title, primaryStyle: .d1, secondary: value, secondaryStyle: .c2, index: index, count: count)
        case .fee(let title, let value):
            return textRow(primary: title, primaryStyle: .c1, secondary: value, secondaryStyle: .d1, index: index, count: count)
        }
    }

}

extension SendXConfirmationViewController {

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()
        viewItems.enumerated().forEach { index, items in
            sections.append(
                    Section(
                            id: "section-\(index)",
                            headerState: .margin(height: .margin12),
                            rows: items.enumerated().map { index, viewItem in
                                row(viewItem: viewItem, index: index, count: items.count)
                            }))
        }

        return sections
    }

}
