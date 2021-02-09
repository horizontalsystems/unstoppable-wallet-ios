import UIKit
import SectionsTableView
import ThemeKit
import RxSwift

class AddressFormatViewController: ThemeViewController {
    private let viewModel: AddressFormatViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private var sectionViewItems = [AddressFormatViewModel.SectionViewItem]()

    init(viewModel: AddressFormatViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "blockchain_settings.title".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.registerCell(forClass: F4Cell.self)
        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)
        tableView.sectionDataSource = self

        subscribe(disposeBag, viewModel.sectionViewItemsDriver) { [weak self] sectionViewItems in
            self?.sectionViewItems = sectionViewItems
            self?.tableView.reload(animated: true)
        }
        subscribe(disposeBag, viewModel.showConfirmationSignal) { [weak self] coinTypeTitle, settingName in
            self?.openConfirmation(coinTypeTitle: coinTypeTitle, settingName: settingName)
        }

        tableView.buildSections()
    }

    private func header(text: String) -> ViewState<SubtitleHeaderFooterView> {
        .cellType(
                hash: text,
                binder: { view in
                    view.bind(text: text)
                },
                dynamicHeight: { _ in
                    SubtitleHeaderFooterView.height
                }
        )
    }

    private func openConfirmation(coinTypeTitle: String, settingName: String) {
        let controller = AddressFormatConfirmationViewController(coinTypeTitle: coinTypeTitle, settingName: settingName, delegate: self)
        present(controller.toBottomSheet, animated: true)
    }

}

extension AddressFormatViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        sectionViewItems.enumerated().map { sectionIndex, sectionViewItem in
            Section(
                    id: sectionViewItem.coinTypeName,
                    headerState: header(text: sectionViewItem.coinTypeName),
                    footerState: .margin(height: .margin8x),
                    rows: sectionViewItem.viewItems.enumerated().map { index, viewItem in
                        let isFirst = index == 0
                        let isLast = index == sectionViewItem.viewItems.count - 1

                        return Row<F4Cell>(
                                id: viewItem.title,
                                hash: "\(viewItem.selected)",
                                height: .heightDoubleLineCell,
                                autoDeselect: true,
                                bind: { cell, _ in
                                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                                    cell.title = viewItem.title
                                    cell.subtitle = viewItem.subtitle
                                    cell.valueImage = viewItem.selected ? UIImage(named: "check_1_20")?.tinted(with: .themeJacob) : nil
                                },
                                action: { [weak self] _ in
                                    self?.viewModel.onSelect(sectionIndex: sectionIndex, index: index)
                                }
                        )
                    }
            )

        }
    }

}

extension AddressFormatViewController: IAddressFormatConfirmationDelegate {

    func onConfirm() {
        viewModel.onConfirm()
    }

}
