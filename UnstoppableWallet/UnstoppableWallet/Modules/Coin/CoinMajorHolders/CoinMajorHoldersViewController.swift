import ComponentKit
import Foundation
import HUD
import RxCocoa
import RxSwift
import SectionsTableView
import SnapKit
import ThemeKit
import UIKit

class CoinMajorHoldersViewController: ThemeViewController {
    private let viewModel: CoinMajorHoldersViewModel
    private let urlManager: UrlManager
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = PlaceholderViewModule.reachabilityView()

    private var stateViewItem: CoinMajorHoldersViewModel.StateViewItem?

    init(viewModel: CoinMajorHoldersViewModel, urlManager: UrlManager) {
        self.viewModel = viewModel
        self.urlManager = urlManager

        super.init()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.blockchainName
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))
        navigationItem.largeTitleDisplayMode = .never

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

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: CoinMajorHolderChartCell.self)
        tableView.registerCell(forClass: CoinAnalyticsHoldersCell.self)

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        subscribe(disposeBag, viewModel.stateViewItemDriver) { [weak self] in
            self?.sync(stateViewItem: $0)
        }
        subscribe(disposeBag, viewModel.loadingDriver) { [weak self] loading in
            self?.spinner.isHidden = !loading
        }
        subscribe(disposeBag, viewModel.syncErrorDriver) { [weak self] visible in
            self?.errorView.isHidden = !visible
        }
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

    @objc private func onRetry() {
        viewModel.onTapRetry()
    }

    private func sync(stateViewItem: CoinMajorHoldersViewModel.StateViewItem?) {
        self.stateViewItem = stateViewItem

        tableView.isHidden = stateViewItem == nil
        tableView.reload()
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
                .vStackCentered([
                    .textElement(text: .body(viewItem.percent)),
                    .margin(1),
                    .textElement(text: .subhead2(viewItem.quantity)),
                ]),
                .secondaryButton { component in
                    component.button.set(style: .default)
                    component.button.setTitle(viewItem.labeledAddress, for: .normal)
                    component.onTap = {
                        CopyHelper.copyAndNotify(value: viewItem.address)
                    }
                },
            ]),
            tableView: tableView,
            id: viewItem.order,
            height: 62,
            bind: { cell in
                cell.set(backgroundStyle: .transparent, isLast: isLast)
            }
        )
    }

    func buildSections() -> [SectionProtocol] {
        guard let stateViewItem else {
            return []
        }

        let chartColor = viewModel.blockchainType.brandColor ?? .themeJacob

        var sections: [SectionProtocol] = [
            Section(
                id: "info",
                headerState: .margin(height: .margin12),
                footerState: .margin(height: .margin12),
                rows: [
                    Row<CoinMajorHolderChartCell>(
                        id: "info",
                        height: CoinMajorHolderChartCell.height,
                        bind: { cell, _ in
                            cell.set(backgroundStyle: .transparent, isFirst: true)
                            cell.bind(percent: stateViewItem.percent, count: stateViewItem.holdersCount)
                        }
                    ),
                ]
            ),
            Section(
                id: "chart",
                footerState: .margin(height: .margin24),
                rows: [
                    Row<CoinAnalyticsHoldersCell>(
                        id: "holders-pie",
                        height: CoinAnalyticsHoldersCell.chartHeight,
                        bind: { cell, _ in
                            cell.set(backgroundStyle: .transparent, isFirst: true)

                            cell.bind(items: [
                                (stateViewItem.totalPercent, chartColor),
                                (stateViewItem.remainingPercent, chartColor.withAlphaComponent(0.5)),
                            ])
                        }
                    ),
                ]
            ),
            Section(
                id: "holders",
                footerState: .margin(height: .margin32),
                rows: stateViewItem.viewItems.enumerated().map { index, viewItem in
                    row(viewItem: viewItem, isLast: index == stateViewItem.viewItems.count - 1)
                }
            ),
        ]

        if let url = stateViewItem.holdersUrl {
            sections.append(
                Section(
                    id: "url",
                    footerState: .margin(height: .margin32),
                    rows: [
                        tableView.universalRow48(
                            id: "url",
                            title: .body("coin_analytics.holders.see_all".localized),
                            accessoryType: .disclosure,
                            autoDeselect: true,
                            isFirst: true,
                            isLast: true,
                            action: { [weak self] in
                                self?.urlManager.open(url: url, from: self)
                            }
                        ),
                    ]
                )
            )
        }

        return sections
    }
}

import Chart
import ComponentKit
import SnapKit
import ThemeKit
import UIKit

class CoinAnalyticsHoldersCell: BaseThemeCell {
    static let chartHeight: CGFloat = 40

    var currentStackView: UIStackView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(items: [(Decimal, UIColor?)]) {
        currentStackView?.removeFromSuperview()
        currentStackView = nil

        let stackView = UIStackView()

        stackView.spacing = 1

        var firstView: UIView?
        var firstPercent: Decimal?
        var alpha: CGFloat = 1

        for (percent, color) in items {
            let view = UIView()

            view.cornerRadius = .cornerRadius2

            let resolvedColor: UIColor

            if let color {
                resolvedColor = color
            } else {
                resolvedColor = UIColor.themeJacob.withAlphaComponent(alpha)
                alpha = max(alpha - 0.25, 0.25)
            }

            view.backgroundColor = resolvedColor

            stackView.addArrangedSubview(view)

            if let firstView, let firstPercent {
                let ratio = percent / firstPercent

                view.snp.makeConstraints { make in
                    make.width.equalTo(firstView).multipliedBy((ratio as NSDecimalNumber).doubleValue)
                }
            } else {
                firstView = view
                firstPercent = percent
            }
        }

        wrapperView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            make.top.equalToSuperview()
            make.height.equalTo(Self.chartHeight)
        }

        currentStackView = stackView
    }
}
