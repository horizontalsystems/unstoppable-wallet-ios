import Combine
import UIKit
import SnapKit
import ThemeKit
import ComponentKit
import SectionsTableView
import HUD

class ReceiveAddressViewController<Service: IReceiveAddressService, Factory: IReceiveAddressViewItemFactory>: ThemeViewController where Service.ServiceItem == Factory.Item {
    private let viewModel: ReceiveAddressViewModel<Service, Factory>
    private var cancellables = Set<AnyCancellable>()

    private let tableView = SectionsTableView(style: .grouped)
    private let spinner = HUDActivityView.create(with: .medium24)
    private let failedView = PlaceholderView()
    private var failedRetryButton: UIButton?
    private let buttonsHolder = BottomGradientHolder()

    private var viewItem: ReceiveAddressModule.ViewItem?
    private var memoWarningShown = false

    private var retryAction: (() -> ())?

    init(viewModel: ReceiveAddressViewModel<Service, Factory>) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.title

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
        failedRetryButton = failedView.addPrimaryButton(
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
                .sink { [weak self] in
                    self?.spinner.isHidden = !$0
                }
                .store(in: &cancellables)

        viewModel.$errorViewItem
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.sync(errorViewItem: $0)
                }
                .store(in: &cancellables)

        viewModel.$viewItem
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.sync(viewItem: $0)
                }
                .store(in: &cancellables)
    }

    private func sync(errorViewItem: ReceiveAddressModule.ErrorItem?) {
        if let errorViewItem {
            failedView.image = UIImage(named: errorViewItem.icon)
            failedView.text = errorViewItem.text
            failedRetryButton?.isHidden = errorViewItem.retryAction == nil
            retryAction = errorViewItem.retryAction
        } else {
            failedView.isHidden = true
            retryAction = nil
        }
    }

    private func sync(viewItem: ReceiveAddressModule.ViewItem?) {
        self.viewItem = viewItem
        tableView.isHidden = viewItem == nil
        buttonsHolder.isHidden = viewItem == nil
        tableView.reload()

        if let viewItem, let popup = viewItem.popup, !memoWarningShown {
            showWarning(item: popup)
            memoWarningShown = true
        }
    }

    @objc private func onTapDone() {
        dismiss(animated: true)
    }

    @objc private func onTapRetry() {
        retryAction?()
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

    private func showWarning(item: ReceiveAddressModule.PopupWarningItem) {
        let viewController = BottomSheetModule.viewController(
                image: .local(image: UIImage(named: "warning_2_24")?.withTintColor(.themeLucian)),
                title: item.title,
                items: [
                    .highlightedDescription(text: item.description.text, style: item.description.style)
                ],
                buttons: [
                    .init(style: .yellow, title: item.doneButtonTitle)
                ]
        )

        present(viewController, animated: true)
    }

    private func showInfo(title: String, description: String) {
        let viewController = BottomSheetModule.description(title: title, text: description)
        present(viewController, animated: true)
    }

}

extension ReceiveAddressViewController: SectionsDataSource {

    private func qrRow(address: String, text: String) -> RowProtocol {
        Row<QrCodeCell>(
                id: "qr-code",
                dynamicHeight: { width in
                    QrCodeCell.height(containerWidth: width, text: text)
                },
                bind: { [weak self] cell, _ in
                    cell.set(qrCodeString: address, text: text)
                    cell.onTap = {
                        self?.onTapCopy()
                    }
                }
        )
    }

    private func valueRow(title: String, value: String, copyable: Bool, rowInfo: RowInfo) -> RowProtocol {
        let backgroundStyle: BaseThemeCell.BackgroundStyle = .lawrence
        let titleFont: UIFont = .subhead2
        let valueFont: UIFont = .subhead1

        return CellBuilderNew.row(
                rootElement: .hStack([
                    .textElement(text: .subhead2(title), parameters: .highResistance),
                    .textElement(text: .subhead1(value), parameters: [.rightAlignment, .multiline]),
                    .secondaryCircleButton { component in
                        component.button.set(image: UIImage(named: "copy_20"))
                        component.onTap = {
                            CopyHelper.copyAndNotify(value: value)
                        }
                        component.isHidden = !copyable
                    }
                ]),
                tableView: tableView,
                id: title + value,
                dynamicHeight: { containerWidth in
                    var elements: [CellBuilderNew.LayoutElement] = [
                        .fixed(width: TextComponent.width(font: titleFont, text: title)),
                        .multiline
                    ]
                    if copyable {
                        elements.append(.fixed(width: SecondaryCircleButton.size))
                    }
                    return CellBuilderNew.height(
                            containerWidth: containerWidth,
                            backgroundStyle: backgroundStyle,
                            text: value,
                            font: valueFont,
                            elements: elements
                    )
                },
                bind: { cell in
                    cell.set(backgroundStyle: backgroundStyle, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                }
        )
    }

    private func infoValueRow(title: String, value: String, infoTitle: String, infoDescription: String, style: HighlightedDescriptionView.Style, rowInfo: RowInfo) -> RowProtocol {
        let color: UIColor
        switch style {
        case .yellow: color = .themeJacob
        case .red: color = .themeLucian
        }

        return CellBuilderNew.row(
                rootElement: .hStack([
                    .textElement(text: .subhead2(title), parameters: .allCompression),
                    .image20 {  component in
                        component.imageView.image = UIImage(named: "circle_information_20")?.withTintColor(.themeGray)
                    },
                    .textElement(text: .subhead1(value, color: color), parameters: [.rightAlignment]),
                ]),
                tableView: tableView,
                id: title + value,
                height: .heightCell48,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                },
                action: { [weak self] in
                    self?.showInfo(title: infoTitle, description: infoDescription)
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        guard let viewItem else {
            return []
        }

        var sections = [SectionProtocol]()

        viewItem.sections.enumerated().forEach { sectionIndex, viewItems in
            var rows = [RowProtocol]()
            viewItems.enumerated().forEach { index, viewItem in
                switch viewItem {
                case let .qrItem(item):
                    rows.append(qrRow(address: item.address, text: item.text))
                case let .value(title, value, copyable):
                    let rowInfo = RowInfo(index: index, count: viewItems.count)
                    rows.append(valueRow(title: title, value: value, copyable: copyable, rowInfo: rowInfo))
                case let .infoValue(title, value, infoTitle, infoDescription, style):
                    let rowInfo = RowInfo(index: index, count: viewItems.count)
                    rows.append(infoValueRow(title: title, value: value, infoTitle: infoTitle, infoDescription: infoDescription, style: style, rowInfo: rowInfo))
                case let .highlightedDescription(text, style):
                    rows.append(tableView.highlightedDescriptionRow(id: "description-\(index)", style: style, text: text, topVerticalMargin: .margin4))
                }
            }

            sections.append(
                    Section(
                            id: "section-\(sectionIndex)",
                            headerState: .margin(height: .margin12),
                            footerState: .margin(height: sectionIndex == viewItem.sections.count - 1 ? .margin32 : 0),
                            rows: rows
                    )
            )
        }

        return sections
    }

}
