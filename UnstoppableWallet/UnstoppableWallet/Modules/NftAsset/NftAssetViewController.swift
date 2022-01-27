import UIKit
import RxSwift
import RxCocoa
import ThemeKit
import ComponentKit
import SectionsTableView

class NftAssetViewController: ThemeViewController {
    private let viewModel: NftAssetViewModel
    private let disposeBag = DisposeBag()

    private var viewItem: NftAssetViewModel.ViewItem?

    private let tableView = SectionsTableView(style: .grouped)

    private var loaded = false

    init(viewModel: NftAssetViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "switch_wallet_24"), style: .plain, target: self, action: #selector(onTapShare))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerCell(forClass: NftAssetTitleCell.self)
        tableView.sectionDataSource = self

        subscribe(disposeBag, viewModel.viewItemDriver) { [weak self] in self?.sync(viewItem: $0) }

        loaded = true
    }

    @objc private func onTapShare() {
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

    private func sync(viewItem: NftAssetViewModel.ViewItem?) {
        self.viewItem = viewItem

        if loaded {
            tableView.reload()
        } else {
            tableView.buildSections()
        }
    }

}

extension NftAssetViewController: SectionsDataSource {

    private func titleSection(title: String, subtitle: String) -> SectionProtocol {
        Section(
                id: "title",
                headerState: .margin(height: .margin24),
                footerState: .margin(height: .margin24),
                rows: [
                    Row<NftAssetTitleCell>(
                            id: "title",
                            dynamicHeight: { width in
                                NftAssetTitleCell.height(containerWidth: width, title: title, subtitle: subtitle)
                            },
                            bind: { cell, _ in
                                cell.bind(title: title, subtitle: subtitle)
                            }
                    )
                ]
        )
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        if let viewItem = viewItem {
            sections.append(titleSection(title: viewItem.name, subtitle: viewItem.collectionName))
        }

        return sections
    }

}
