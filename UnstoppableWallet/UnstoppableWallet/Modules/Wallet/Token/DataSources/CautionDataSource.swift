import Combine
import ComponentKit
import Foundation
import HUD
import MarketKit
import SectionsTableView
import ThemeKit
import UIKit

class CautionDataSource: NSObject {
    private let viewModel: ICautionDataSourceViewModel
    private var cancellables: [AnyCancellable] = []

    private var caution: TitledCaution?
    private var tableView: UITableView?

    weak var parentViewController: UIViewController?
    weak var delegate: ISectionDataSourceDelegate?

    init(viewModel: ICautionDataSourceViewModel) {
        self.viewModel = viewModel

        super.init()

        viewModel.cautionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.sync(caution: $0)
            }
            .store(in: &cancellables)

        sync(caution: viewModel.caution)
    }

    private func sync(caution: TitledCaution?) {
        let oldCautionExists = self.caution != nil
        let newCautionExists = caution != nil
        self.caution = caution

        guard oldCautionExists == newCautionExists else {
            tableView?.reloadData()
            return
        }

        if let tableView {
            if newCautionExists {
                let indexPath = IndexPath(row: 0, section: 0)
                let originalIndexPath = delegate?
                    .originalIndexPath(tableView: tableView, dataSource: self, indexPath: indexPath) ?? indexPath

                if let cell = tableView.cellForRow(at: originalIndexPath) as? TitledHighlightedDescriptionCell {
                    bind(cell: cell, row: 0)
                }
            }
        }
    }

    private func bind(cell: TitledHighlightedDescriptionCell, row _: Int) {
        guard let caution else {
            return
        }
        cell.set(backgroundStyle: .externalBorderOnly, cornerRadius: .margin12, isFirst: true, isLast: true)
        cell.bind(caution: caution)
    }
}

extension CautionDataSource: ISectionDataSource {
    func prepare(tableView: UITableView) {
        tableView.registerCell(forClass: TitledHighlightedDescriptionCell.self)
        tableView.registerHeaderFooter(forClass: SectionColorHeader.self)
        self.tableView = tableView
    }
}

extension CautionDataSource: UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        caution == nil ? 0 : 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let originalIndexPath = delegate?.originalIndexPath(tableView: tableView, dataSource: self, indexPath: indexPath) ?? indexPath
        return tableView.dequeueReusableCell(withIdentifier: String(describing: TitledHighlightedDescriptionCell.self), for: originalIndexPath)
    }
}

extension CautionDataSource: UITableViewDelegate {
    func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? TitledHighlightedDescriptionCell {
            bind(cell: cell, row: indexPath.row)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        guard let caution else {
            return 0
        }

        return TitledHighlightedDescriptionCell.height(containerWidth: tableView.width, text: caution.text)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        guard caution != nil else {
            return nil
        }

        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: SectionColorHeader.self)) as? SectionColorHeader
        view?.backgroundView?.backgroundColor = .clear
        return view
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        caution == nil ? .zero : .margin8
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        caution == nil ? .zero : .margin16
    }
}
