import UIKit
import SnapKit
import ThemeKit
import SectionsTableView
import HUD
import RxSwift
import ComponentKit

class FaqViewController: ThemeViewController {
    private let viewModel: FaqViewModel

    private let tableView = SectionsTableView(style: .grouped)

    private let spinner = HUDActivityView.create(with: .large48)

    private let errorLabel = UILabel()
    private var sectionItems = [FaqService.SectionItem]()

    private let disposeBag = DisposeBag()

    init(viewModel: FaqViewModel) {
        self.viewModel = viewModel

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "faq.title".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.sectionDataSource = self

        tableView.registerCell(forClass: FaqCell.self)
        tableView.registerCell(forClass: BCell.self)

        view.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        view.addSubview(errorLabel)
        errorLabel.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        errorLabel.font = .subhead2
        errorLabel.textColor = .themeGray

        viewModel.sectionItemsDriver
                .drive(onNext: { [weak self] sectionItems in
                    self?.sectionItems = sectionItems
                    self?.tableView.reload()
                })
                .disposed(by: disposeBag)

        viewModel.loadingDriver
                .drive(onNext: { [weak self] loading in
                    self?.setSpinner(visible: loading)
                })
                .disposed(by: disposeBag)

        viewModel.errorDriver
                .drive(onNext: { [weak self] error in
                    self?.errorLabel.text = error?.smartDescription
                })
                .disposed(by: disposeBag)

        tableView.buildSections()
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    private func setSpinner(visible: Bool) {
        if visible {
            spinner.isHidden = false
            spinner.startAnimating()
        } else {
            spinner.isHidden = true
            spinner.stopAnimating()
        }
    }

}

extension FaqViewController: SectionsDataSource {

    private func headerSection(index: Int, title: String) -> SectionProtocol {
        Section(
                id: "header-\(index)",
                headerState: .margin(height: .margin12),
                footerState: .margin(height: .margin8),
                rows: [
                    Row<BCell>(
                            id: "header-\(index)",
                            height: .heightSingleLineCell,
                            bind: { cell, _ in
                                cell.set(backgroundStyle: .transparent)
                                cell.selectionStyle = .none
                                cell.title = title
                            }
                    )
                ]
        )
    }

    private func itemsSection(sectionIndex: Int, isLastSection: Bool, items: [FaqService.Item]) -> SectionProtocol {
        Section(
                id: "items-\(sectionIndex)",
                footerState: .margin(height: isLastSection ? .margin32 : 0),
                rows: items.enumerated().map { index, item in
                    let isFirst = index == 0
                    let isLast = index == items.count - 1

                    return Row<FaqCell>(
                            id: "faq-\(sectionIndex)-\(index)",
                            dynamicHeight: { containerWidth in
                                FaqCell.height(containerWidth: containerWidth, text: item.text, backgroundStyle: .lawrence)
                            },
                            bind: { cell, _ in
                                cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                                cell.title = item.text
                            },
                            action: { [weak self] _ in
                                guard let url = item.url else {
                                    return
                                }

                                let module = MarkdownModule.viewController(url: url, handleRelativeUrl: false)
                                self?.navigationController?.pushViewController(module, animated: true)
                            }
                    )
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        for (index, sectionItem) in sectionItems.enumerated() {
            sections.append(headerSection(index: index, title: sectionItem.title))
            sections.append(itemsSection(sectionIndex: index, isLastSection: index == sectionItems.count - 1, items: sectionItem.items))
        }

        return sections
    }

}
