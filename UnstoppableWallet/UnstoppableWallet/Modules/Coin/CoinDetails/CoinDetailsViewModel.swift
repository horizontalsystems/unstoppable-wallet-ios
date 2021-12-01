import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MarketKit
import Chart

class CoinDetailsViewModel {
    private let service: CoinDetailsService
    private let disposeBag = DisposeBag()

    private let viewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    private let ratioFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.roundingMode = .halfUp
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    init(service: CoinDetailsService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: DataStatus<CoinDetailsService.Item>) {
        switch state {
        case .loading:
            viewItemRelay.accept(nil)
            loadingRelay.accept(true)
            errorRelay.accept(nil)
        case .completed(let item):
            viewItemRelay.accept(viewItem(item: item))
            loadingRelay.accept(false)
            errorRelay.accept(nil)
        case .failed:
            viewItemRelay.accept(nil)
            loadingRelay.accept(false)
            errorRelay.accept("market.sync_error".localized)
        }
    }

    private func chart(values: [ChartPoint]?, badge: String? = nil) -> ChartViewItem? {
        guard let values = values, let first = values.first, let last = values.last else {
            return nil
        }

        let chartItems = values.map {
            ChartItem(timestamp: $0.timestamp).added(name: .rate, value: $0.value)
        }

        let diff = (last.value / first.value - 1) * 100
        let chartData = ChartData(items: chartItems, startTimestamp: first.timestamp, endTimestamp: last.timestamp)
        let value = CurrencyCompactFormatter.instance.format(currency: service.currency, value: last.value)

        return ChartViewItem(badge: badge, value: value, diff: diff, chartData: chartData, chartTrend: diff.isSignMinus ? .down : .up)
    }

    private func viewItem(item: CoinDetailsService.Item) -> ViewItem {
        ViewItem(
                hasMajorHolders: service.hasMajorHolders,
                volumeChart: chart(values: item.totalVolumes, badge: service.coin.marketCapRank.map { "#\($0)" }),
                tvlChart: chart(values: item.tvls),
                tvlRank: item.marketInfoDetails.tvlRank.map { "#\($0)" },
                tvlRatio: item.marketInfoDetails.tvlRatio.flatMap { ratioFormatter.string(from: $0 as NSNumber) },
                treasuries: item.marketInfoDetails.totalTreasuries.flatMap { CurrencyCompactFormatter.instance.format(currency: service.currency, value: $0) },
                fundsInvested: item.marketInfoDetails.totalFundsInvested.flatMap { CurrencyCompactFormatter.instance.format(currency: service.usdCurrency, value: $0) },
                reportsCount: item.marketInfoDetails.reportsCount == 0 ? nil : "\(item.marketInfoDetails.reportsCount)",
                securityViewItems: securityViewItems(info: item.marketInfoDetails),
                auditAddresses: service.auditAddresses
        )
    }

    private func securityViewItems(info: MarketInfoDetails) -> [SecurityViewItem] {
        var viewItems = [SecurityViewItem]()

        if let kitPrivacy = info.privacy {
            let privacy: SecurityLevel
            switch kitPrivacy {
            case .low: privacy = .low
            case .medium: privacy = .medium
            case .high: privacy = .high
            }

            viewItems.append(SecurityViewItem(type: .privacy, value: privacy.title, valueGrade: privacy.grade))
        }

        if let kitIssuance = info.decentralizedIssuance {
            let issuance: SecurityIssuance = kitIssuance ? .decentralized : .centralized
            viewItems.append(SecurityViewItem(type: .issuance, value: issuance.title, valueGrade: issuance.grade))
        }

        if let kitResistant = info.confiscationResistant {
            let resistance: SecurityResistance = kitResistant ? .yes : .no
            viewItems.append(SecurityViewItem(type: .confiscationResistance, value: resistance.title, valueGrade: resistance.grade))
        }

        if let kitResistant = info.censorshipResistant {
            let resistance: SecurityResistance = kitResistant ? .yes : .no
            viewItems.append(SecurityViewItem(type: .censorshipResistance, value: resistance.title, valueGrade: resistance.grade))
        }

        return viewItems
    }

}

extension CoinDetailsViewModel {

    var viewItemDriver: Driver<ViewItem?> {
        viewItemRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    var coin: Coin {
        service.coin
    }

    func onLoad() {
        service.sync()
    }

    func onTapRetry() {
        service.sync()
    }

    func securityInfoViewItems(type: SecurityType) -> [SecurityInfoViewItem] {
        switch type {
        case .privacy:
            return SecurityLevel.allCases.map { level in
                SecurityInfoViewItem(grade: level.grade, title: level.title, text: "coin_page.security_parameters.privacy.description.\(level.rawValue)".localized)
            }
        case .issuance:
            return SecurityIssuance.allCases.map { issuance in
                SecurityInfoViewItem(grade: issuance.grade, title: issuance.title, text: "coin_page.security_parameters.issuance.description.\(issuance.rawValue)".localized)
            }
        case .confiscationResistance:
            return SecurityResistance.allCases.map { resistance in
                SecurityInfoViewItem(grade: resistance.grade, title: resistance.title, text: "coin_page.security_parameters.confiscation_resistance.description.\(resistance.rawValue)".localized)
            }
        case .censorshipResistance:
            return SecurityResistance.allCases.map { resistance in
                SecurityInfoViewItem(grade: resistance.grade, title: resistance.title, text: "coin_page.security_parameters.censorship_resistance.description.\(resistance.rawValue)".localized)
            }
        }
    }

}

extension CoinDetailsViewModel {

    struct ViewItem {
        let hasMajorHolders: Bool
        let volumeChart: ChartViewItem?
        let tvlChart: ChartViewItem?
        let tvlRank: String?
        let tvlRatio: String?
        let treasuries: String?
        let fundsInvested: String?
        let reportsCount: String?
        let securityViewItems: [SecurityViewItem]
        let auditAddresses: [String]
    }

    struct SecurityViewItem {
        let type: SecurityType
        let value: String
        let valueGrade: SecurityGrade
    }

    struct SecurityInfoViewItem {
        let grade: SecurityGrade
        let title: String
        let text: String
    }

    enum SecurityLevel: String, CaseIterable {
        case low
        case medium
        case high

        var title: String {
            "coin_page.security_parameters.level.\(rawValue)".localized
        }

        var grade: SecurityGrade {
            switch self {
            case .low: return .low
            case .medium: return .medium
            case .high: return .high
            }
        }
    }

    enum SecurityIssuance: String, CaseIterable {
        case decentralized
        case centralized

        var title: String {
            "coin_page.security_parameters.issuance.\(rawValue)".localized
        }

        var grade: SecurityGrade {
            switch self {
            case .decentralized: return .high
            case .centralized: return .low
            }
        }
    }

    enum SecurityResistance: String, CaseIterable {
        case yes
        case no

        var title: String {
            "coin_page.security_parameters.resistance.\(rawValue)".localized
        }

        var grade: SecurityGrade {
            switch self {
            case .yes: return .high
            case .no: return .low
            }
        }
    }

    enum SecurityGrade {
        case low
        case medium
        case high
    }

    enum SecurityType {
        case privacy
        case issuance
        case confiscationResistance
        case censorshipResistance

        var title: String {
            switch self {
            case .privacy: return "coin_page.security_parameters.privacy".localized
            case .issuance: return "coin_page.security_parameters.issuance".localized
            case .confiscationResistance: return "coin_page.security_parameters.confiscation_resistance".localized
            case .censorshipResistance: return "coin_page.security_parameters.censorship_resistance".localized
            }
        }
    }

    struct ChartViewItem {
        let badge: String?
        let value: String?
        let diff: Decimal?
        let chartData: ChartData?
        let chartTrend: MovementTrend
    }

}
