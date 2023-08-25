import Combine
import Foundation
import UIKit

protocol ISectionDataSource: UITableViewDelegate, UITableViewDataSource {
    var indexPathConverter: ISectionDataSourceIndexPathConverter? { get set }
    func prepare(tableView: UITableView)
}

protocol ISectionDataSourceIndexPathConverter: AnyObject {
    func originalIndexPath(tableView: UITableView, dataSource: ISectionDataSource, indexPath: IndexPath) -> IndexPath
}

extension ISectionDataSourceIndexPathConverter {

    func originalIndexPath(tableView: UITableView, dataSource: ISectionDataSource, indexPath: IndexPath) -> IndexPath {
        indexPath
    }

}

class DataSourceChain: NSObject {
    private var dataSources = [ISectionDataSource]()
    private var cancellables: [AnyCancellable] = []

    weak var indexPathConverter: ISectionDataSourceIndexPathConverter? // unused

    func append(source: ISectionDataSource) {
        dataSources.append(source)
        source.indexPathConverter = self
    }

    private func sectionCount(tableView: UITableView, before section: Int) -> Int {
        dataSources
                .prefix(section)
                .map { $0.numberOfSections?(in: tableView) ?? 0 }
                .reduce(0, +)
    }

    private func sourceIndex(_ tableView: UITableView, `for` section: Int) -> Int {
        var shift = 0
        for (index, dataSource) in dataSources.enumerated() {
            let count = dataSource.numberOfSections?(in: tableView) ?? 0
            shift += count

            if shift > section {
                return index
            }
        }
        return 0
    }

    private func sourcePath(_ tableView: UITableView, forRowAt indexPath: IndexPath) -> SourceIndexPath {
        let sourceIndex = sourceIndex(tableView, for: indexPath.section)
        let sectionCountBefore = sectionCount(tableView: tableView, before: sourceIndex)

        let path = IndexPath(row: indexPath.row, section: indexPath.section - sectionCountBefore)
        return SourceIndexPath(source: sourceIndex, indexPath: path)
    }

}

extension DataSourceChain: ISectionDataSourceIndexPathConverter {

    func originalIndexPath(tableView: UITableView, dataSource: ISectionDataSource, indexPath: IndexPath) -> IndexPath {
        guard let dataSourceIndex = dataSources.firstIndex(where: { $0.isEqual(dataSource) }) else {
            return indexPath
        }

        let sectionCountBefore = sectionCount(tableView: tableView, before: dataSourceIndex)
        return IndexPath(row: indexPath.row, section: indexPath.section + sectionCountBefore)
    }

}

extension DataSourceChain: ISectionDataSource {

    func prepare(tableView: UITableView) {
        dataSources.forEach { $0.prepare(tableView: tableView) }
    }

}

extension DataSourceChain: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        sectionCount(tableView: tableView, before: dataSources.count)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let index = sourceIndex(tableView, for: section)
        let sectionCountBefore = sectionCount(tableView: tableView, before: index)

        return dataSources[index].tableView(tableView, numberOfRowsInSection: section - sectionCountBefore)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sourcePath = sourcePath(tableView, forRowAt: indexPath)
        return dataSources[sourcePath.source].tableView(tableView, cellForRowAt: sourcePath.indexPath)
    }

}

extension DataSourceChain: UITableViewDelegate {

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let sourcePath = sourcePath(tableView, forRowAt: indexPath)
        dataSources[sourcePath.source].tableView?(tableView, willDisplay: cell, forRowAt: sourcePath.indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sourcePath = sourcePath(tableView, forRowAt: indexPath)
        return dataSources[sourcePath.source].tableView?(tableView, heightForRowAt: sourcePath.indexPath) ?? 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sourcePath = sourcePath(tableView, forRowAt: indexPath)

        dataSources[sourcePath.source].tableView?(tableView, didSelectRowAt: sourcePath.indexPath)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let sourcePath = sourcePath(tableView, forRowAt: IndexPath(row: 0, section: section))
        return dataSources[sourcePath.source].tableView?(tableView, heightForHeaderInSection: sourcePath.indexPath.section) ?? 0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sourcePath = sourcePath(tableView, forRowAt: IndexPath(row: 0, section: section))
        return dataSources[sourcePath.source].tableView?(tableView, viewForHeaderInSection: sourcePath.indexPath.section)
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let sourcePath = sourcePath(tableView, forRowAt: IndexPath(row: 0, section: section))
        dataSources[sourcePath.source].tableView?(tableView, willDisplayHeaderView: view, forSection: sourcePath.indexPath.section)
    }


}

extension DataSourceChain {

    private struct SourceIndexPath {
        let source: Int
        let indexPath: IndexPath
    }

}
