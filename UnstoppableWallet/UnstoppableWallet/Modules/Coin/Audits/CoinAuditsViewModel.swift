import Combine
import Foundation
import MarketKit

class CoinAuditsViewModel: ObservableObject {
    let viewItems: [ViewItem]

    init(audits: [Analytics.Audit]) {
        viewItems = CoinAuditsViewModel.convert(audits: audits)
    }

    private static func convert(audits: [Analytics.Audit]) -> [ViewItem] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var viewItems = [ViewItem]()
        var grouped = [String: [AuditViewItem]]()

        for audit in audits {
            guard let partnerName = audit.partnerName else {
                continue
            }

            guard let date = dateFormatter.date(from: audit.date) else {
                continue
            }

            if grouped[partnerName] == nil {
                grouped[partnerName] = [AuditViewItem]()
            }

            grouped[partnerName]?.append(
                AuditViewItem(
                    rawDate: date,
                    date: DateHelper.instance.formatFullDateOnly(from: date),
                    name: audit.name,
                    issues: "coin_analytics.audits.issues".localized + ": \(audit.techIssues ?? 0)",
                    reportUrl: audit.auditUrl
                )
            )
        }

        for (auditor, reports) in grouped {
            viewItems.append(
                ViewItem(
                    logoUrl: Analytics.Audit.logoUrl(name: auditor),
                    name: auditor,
                    lastDate: reports.map(\.rawDate).max(),
                    auditViewItems: reports
                )
            )
        }

        viewItems.sort { lhsViewItem, rhsViewItem in
            guard let lhsDate = lhsViewItem.lastDate, let rhsDate = rhsViewItem.lastDate else {
                return false
            }

            return lhsDate > rhsDate
        }

        return viewItems
    }
}

extension CoinAuditsViewModel {
    struct ViewItem {
        let logoUrl: String?
        let name: String
        let lastDate: Date?
        let auditViewItems: [AuditViewItem]
    }

    struct AuditViewItem {
        let rawDate: Date
        let date: String
        let name: String
        let issues: String
        let reportUrl: String?
    }
}
