import Foundation
import UIKit
import RxSwift
import RxCocoa
import SnapKit
import ThemeKit
import SectionsTableView
import ComponentKit
import HUD

class CoinInvestorsViewController: ThemeViewController {
    private let viewModel: CoinInvestorsViewModel
    private let urlManager: UrlManager
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = PlaceholderViewModule.reachabilityView()

    private var viewItems: [CoinInvestorsViewModel.ViewItem]?

    init(viewModel: CoinInvestorsViewModel, urlManager: UrlManager) {
        self.viewModel = viewModel
        self.urlManager = urlManager

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "coin_page.funds_invested".localized

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

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.sync(viewItems: $0) }
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

    private func sync(viewItems: [CoinInvestorsViewModel.ViewItem]?) {
        self.viewItems = viewItems

        if viewItems != nil {
            tableView.bounces = true
        } else {
            tableView.bounces = false
        }

        tableView.reload()
    }

}

extension CoinInvestorsViewController: SectionsDataSource {

    private func headerSection(index: Int, title: String, value: String) -> SectionProtocol {
        Section(
                id: "header-\(index)",
                headerState: .margin(height: .margin12),
                footerState: .margin(height: .margin12),
                rows: [
                    tableView.titleValueArrowRow(
                            id: "header-\(index)",
                            title: SectionsTableView.Text(text: title, font: .body, textColor: .themeJacob),
                            value: .body(value),
                            showArrow: false,
                            backgroundStyle: .transparent
                    )
                ]
        )
    }

    private func row(fundViewItem: CoinInvestorsViewModel.FundViewItem, isFirst: Bool, isLast: Bool) -> RowProtocol {
        var elements = [CellBuilderNew.CellElement]()
        elements.append(.image32 { (component: ImageComponent) -> () in
            component.setImage(urlString: fundViewItem.logoUrl, placeholder: UIImage(named: "placeholder_circle_32"))
        })
        elements.append(.text { (component: TextComponent) -> () in
            component.font = .body
            component.textColor = .themeLeah
            component.text = fundViewItem.name
        })
        elements.append(.text { (component: TextComponent) -> () in
            component.isHidden = !fundViewItem.isLead
            component.font = .subhead1
            component.textColor = .themeRemus
            component.text = "coin_page.funds_invested.lead".localized
        })

        if !fundViewItem.url.isEmpty {
            elements.append(.margin8)
            elements.append(.image20 { (component: ImageComponent) -> () in
                component.imageView.image = UIImage(named: "arrow_big_forward_20")?.withTintColor(.themeGray)
            })
        }
        return CellBuilderNew.row(
                rootElement: .hStack(elements),
                tableView: tableView,
                id: fundViewItem.uid,
                height: .heightCell56,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                },
                action: { [weak self] in
                    self?.urlManager.open(url: fundViewItem.url, from: self)
                }
        )
    }

    private func section(index: Int, fundViewItems: [CoinInvestorsViewModel.FundViewItem], isLast: Bool) -> SectionProtocol {
        Section(
                id: "section-\(index)",
                footerState: .margin(height: isLast ? .margin32 : 0),
                rows: fundViewItems.enumerated().map { index, fundViewItem in
                    row(fundViewItem: fundViewItem, isFirst: index == 0, isLast: index == fundViewItems.count - 1)
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        guard let viewItems = viewItems else {
            return []
        }

        var sections = [SectionProtocol]()

        for (index, viewItem) in viewItems.enumerated() {
            sections.append(headerSection(index: index, title: viewItem.amount, value: viewItem.info))
            sections.append(section(index: index, fundViewItems: viewItem.fundViewItems, isLast: index == viewItems.count - 1))
        }

        return sections
    }

}
