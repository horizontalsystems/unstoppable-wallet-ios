import Foundation
import MarketKit
import HsExtensions

class CoinAuditsService {
    private let addresses: [String]
    private let marketKit: Kit
    private var tasks = Set<AnyTask>()

    @PostPublished private(set) var state: DataStatus<[Item]> = .loading

    init(addresses: [String], marketKit: Kit) {
        self.addresses = addresses
        self.marketKit = marketKit

        sync()
    }

    private func sync() {
        tasks = Set()

        state = .loading

        Task { [weak self, marketKit, addresses] in
            do {
                let auditors = try await marketKit.auditReports(addresses: addresses)
                self?.handle(auditors: auditors)
            } catch {
                self?.state = .failed(error)
            }
        }.store(in: &tasks)
    }

    private func handle(auditors: [Auditor]) {
        let items = auditors.map { auditor -> Item in
            let sortedReports = auditor.reports.sorted { $0.date > $1.date }

            return Item(
                    logoUrl: auditor.logoUrl,
                    name: auditor.name,
                    latestDate: sortedReports.first?.date ?? Date(timeIntervalSince1970: 0),
                    reports: sortedReports
            )
        }

        state = .completed(items.sorted { $0.latestDate > $1.latestDate })
    }

}

extension CoinAuditsService {

    func refresh() {
        sync()
    }

}

extension CoinAuditsService {

    struct Item {
        let logoUrl: String?
        let name: String
        let latestDate: Date
        let reports: [AuditReport]
    }

}
