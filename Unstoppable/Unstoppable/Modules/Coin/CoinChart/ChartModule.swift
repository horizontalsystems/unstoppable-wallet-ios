import Chart
import Foundation
import RxCocoa
import UIKit

enum ChartModule {
    struct ViewItem {
        let value: String?
        let valueDescription: String?
        let rightSideMode: RightSideMode

        let chartData: ChartData
        let indicators: [ChartIndicator]
        let chartTrend: MovementTrend
        let chartDiff: ValueDiff?

        let limitFormatter: ((Decimal) -> String?)?
    }

    struct SelectedPointViewItem {
        let value: String?
        let diff: ValueDiff?
        let date: String
        let rightSideMode: RightSideMode

        init(value: String?, diff: ValueDiff? = nil, date: String, rightSideMode: RightSideMode) {
            self.value = value
            self.diff = diff
            self.date = date
            self.rightSideMode = rightSideMode
        }
    }

    enum RightSideMode {
        case none
        case volume(value: String?)
        case dominance(value: Decimal?, diff: Decimal?)
        case custom(title: String, value: String?)
        case indicators(top: NSAttributedString?, bottom: NSAttributedString?)
    }
}

enum MovementTrend {
    case up
    case down
    case neutral
    case ignored

    var chartColorType: ChartColorType {
        switch self {
        case .up: return .up
        case .down: return .down
        case .neutral: return .neutral
        case .ignored: return .pressed
        }
    }
}

struct ValueDiff {
    let value: String
    let trend: MovementTrend
}

protocol IChartViewModel {
    var showAll: Bool { get }
    var intervals: [String] { get }
    var intervalsUpdatedWithCurrentIndexDriver: Driver<Int> { get }
    var pointSelectedItemDriver: Driver<ChartModule.SelectedPointViewItem?> { get }
    var loadingDriver: Driver<Bool> { get }
    var indicatorsShownDriver: Driver<Bool> { get }
    var chartInfoDriver: Driver<ChartModule.ViewItem?> { get }
    var errorDriver: Driver<Bool> { get }

    func onSelectInterval(at index: Int)
    func start()
    func retry()
}
