import Combine
import Foundation
import MarketKit
import RxCocoa
import RxRelay
import RxSwift

class CoinAuditsViewModel {
    let viewItems: [ViewItem]

    init(items: [Analytics.Audit]) {
        viewItems = CoinAuditsViewModel.convert(audits: items)
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

            grouped[partnerName]?.append(AuditViewItem(
                date: DateHelper.instance.formatFullDateOnly(from: date),
                name: audit.name,
                issues: "coin_analytics.audits.issues".localized + ": \(audit.techIssues ?? 0)",
                reportUrl: audit.auditUrl
            )
            )
        }

        for (auditor, reports) in grouped {
            viewItems.append(ViewItem(
                logoUrl: Analytics.Audit.logoUrl(name: auditor),
                name: auditor,
                auditViewItems: reports
            )
            )
        }

        return viewItems
    }
}

extension CoinAuditsViewModel {
    struct ViewItem {
        let logoUrl: String?
        let name: String
        let auditViewItems: [AuditViewItem]
    }

    struct AuditViewItem {
        let date: String?
        let name: String
        let issues: String
        let reportUrl: String?
    }
}
