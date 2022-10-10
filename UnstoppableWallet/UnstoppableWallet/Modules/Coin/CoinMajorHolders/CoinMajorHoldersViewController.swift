import Foundation
import UIKit
import ThemeKit
import SnapKit
import SectionsTableView
import ComponentKit
import RxSwift
import RxCocoa
import HUD

class CoinMajorHoldersViewController: ThemeViewController {
    private let viewModel: CoinMajorHoldersViewModel
    private let urlManager: UrlManager
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = PlaceholderViewModule.reachabilityView()
    private var chartCell = CoinMajorHolderChartCell()

    private var stateViewItem: CoinMajorHoldersViewModel.StateViewItem?

    init(viewModel: CoinMajorHoldersViewModel, urlManager: UrlManager) {
        self.viewModel = viewModel
        self.urlManager = urlManager

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "coin_page.major_holders".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.sectionDataSource = self

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        view.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        spinner.startAnimating()

        view.addSubview(errorView)
        errorView.snp.makeConstraints { maker in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }

        errorView.configureSyncError(action: { [weak self] in self?.onRetry() })

        subscribe(disposeBag, viewModel.stateViewItemDriver) { [weak self] in self?.sync(stateViewItem: $0) }
        subscribe(disposeBag, viewModel.loadingDriver) { [weak self] loading in
            self?.spinner.isHidden = !loading
        }
        subscribe(disposeBag, viewModel.syncErrorDriver) { [weak self] visible in
            self?.errorView.isHidden = !visible
        }
    }

    @objc private func onRetry() {
        viewModel.onTapRetry()
    }

    private func sync(stateViewItem: CoinMajorHoldersViewModel.StateViewItem?) {
        self.stateViewItem = stateViewItem

        if let stateViewItem = stateViewItem {
            tableView.bounces = true
            chartCell.set(chartPercents: stateViewItem.chartPercents, percent: stateViewItem.percent)
        } else {
            tableView.bounces = false
        }

        tableView.reload()
    }

    private func open(address: String) {
        urlManager.open(url: "https://etherscan.io/address/\(address)", from: self)
    }

}

extension CoinMajorHoldersViewController: SectionsDataSource {

    private func row(viewItem: CoinMajorHoldersViewModel.ViewItem, isLast: Bool) -> RowProtocol {
        CellBuilderNew.row(
                rootElement: .hStack([
                    .text { component in
                        component.font = .captionSB
                        component.textColor = .themeGray
                        component.text = viewItem.order
                        component.textAlignment = .center

                        component.snp.remakeConstraints { maker in
                            maker.width.equalTo(24)
                        }
                    },
                    .text { component in
                        component.font = .body
                        component.textColor = .themeJacob
                        component.text = viewItem.percent
                    },
                    .secondaryButton { component in
                        component.button.set(style: .default)
                        component.button.setTitle(viewItem.address.shortened, for: .normal)
                        component.onTap = {
                            CopyHelper.copyAndNotify(value: viewItem.address)
                        }

                        component.snp.remakeConstraints { maker in
                            maker.width.equalTo(140)
                        }
                    },
                    .margin8,
                    .secondaryCircleButton { [weak self] component in
                        component.button.set(image: UIImage(named: "globe_20"))
                        component.onTap = {
                            self?.open(address: viewItem.address)
                        }
                    }
                ]),
                tableView: tableView,
                id: viewItem.order,
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .transparent, isLast: isLast)
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        guard let stateViewItem = stateViewItem else {
            return []
        }

        return [
            Section(
                    id: "chart",
                    rows: [
                        StaticRow(
                                cell: chartCell,
                                id: "chart",
                                dynamicHeight: { width in
                                    CoinMajorHolderChartCell.height(containerWidth: width)
                                }
                        )
                    ]
            ),
            Section(
                    id: "holders",
                    footerState: .margin(height: .margin32),
                    rows: [tableView.subtitleRow(text: "coin_page.major_holders.top_ethereum_wallets".localized)]
                            + stateViewItem.viewItems.enumerated().map { row(viewItem: $1, isLast: $0 == stateViewItem.viewItems.count - 1) }
            )
        ]
    }

}
