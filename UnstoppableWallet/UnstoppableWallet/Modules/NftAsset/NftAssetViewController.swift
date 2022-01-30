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
    private let descriptionTextCell = ReadMoreTextCell()

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
        tableView.registerCell(forClass: TextCell.self)
        tableView.registerCell(forClass: BrandFooterCell.self)
        tableView.sectionDataSource = self

        descriptionTextCell.set(backgroundStyle: .transparent, isFirst: true)
        descriptionTextCell.onChangeHeight = { [weak self] in
            self?.reloadTable()
        }

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

    private func reloadTable() {
        tableView.buildSections()

        tableView.beginUpdates()
        tableView.endUpdates()
    }

}

extension NftAssetViewController: SectionsDataSource {

    private func headerRow(title: String) -> RowProtocol {
        CellBuilder.row(
                elements: [.text],
                tableView: tableView,
                id: "header-\(title)",
                hash: title,
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .transparent)

                    cell.bind(index: 0) { (component: TextComponent) in
                        component.set(style: .b2)
                        component.text = title
                    }
                }
        )
    }

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

    private func traitsSection(traits: [NftAssetViewModel.TraitViewItem]) -> SectionProtocol {
        let text = traits.map { "\($0.type) - \($0.value)\($0.percent.map { " - \($0)" } ?? "")" }.joined(separator: "\n")

        return Section(
                id: "traits",
                headerState: .margin(height: .margin12),
                rows: [
                    headerRow(title: "nft_asset.properties".localized),
                    Row<TextCell>(
                            id: "traits",
                            dynamicHeight: { width in
                                TextCell.height(containerWidth: width, text: text)
                            },
                            bind: { cell, _ in
                                cell.contentText = text
                            }
                    )
                ]
        )
    }

    private func descriptionSection(description: String) -> SectionProtocol {
        descriptionTextCell.contentText = NSAttributedString(string: description, attributes: [.font: UIFont.subhead2, .foregroundColor: UIColor.themeGray])

        let descriptionRow = StaticRow(
                cell: descriptionTextCell,
                id: "description",
                dynamicHeight: { [weak self] containerWidth in
                    self?.descriptionTextCell.cellHeight(containerWidth: containerWidth) ?? 0
                }
        )

        return Section(
                id: "description",
                headerState: .margin(height: .margin12),
                rows: [
                    headerRow(title: "nft_asset.description".localized),
                    descriptionRow
                ]
        )
    }

    private func poweredBySection(text: String) -> SectionProtocol {
        Section(
                id: "powered-by",
                headerState: .margin(height: .margin32),
                rows: [
                    Row<BrandFooterCell>(
                            id: "powered-by",
                            dynamicHeight: { containerWidth in
                                BrandFooterCell.height(containerWidth: containerWidth, title: text)
                            },
                            bind: { cell, _ in
                                cell.title = text
                            }
                    )
                ]
        )
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        if let viewItem = viewItem {
            sections.append(titleSection(title: viewItem.name, subtitle: viewItem.collectionName))

            if !viewItem.traits.isEmpty {
                sections.append(traitsSection(traits: viewItem.traits))
            }

            if let description = viewItem.description {
                sections.append(descriptionSection(description: description))
            }

            sections.append(poweredBySection(text: "Powered by OpenSea API"))
        }

        return sections
    }

}
