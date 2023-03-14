import Foundation
import UIKit
import RxCocoa
import CurrencyKit
import Chart

struct ChartModule {

    struct ViewItem {
        let value: String?
        let rightSideMode: RightSideMode

        let chartData: ChartData
        let chartTrend: MovementTrend
        let chartDiff: Decimal?

        let minValue: String?
        let maxValue: String?
    }

    struct SelectedPointViewItem {
        let value: String?
        let diff: Decimal?
        let date: String
        let rightSideMode: RightSideMode
    }

    enum RightSideMode {
        case none
        case volume(value: String?)
        case dominance(value: Decimal?, diff: Decimal?)
    }

}

enum MovementTrend {
    case ignore
    case neutral
    case down
    case up
}

protocol IChartViewModel {
    var chartTitle: String? { get }
    var intervals: [String] { get }
    var intervalsUpdatedWithCurrentIndexDriver: Driver<Int> { get }
    var intervalIndexDriver: Driver<Int> { get }
    var pointSelectModeEnabledDriver: Driver<Bool> { get }
    var pointSelectedItemDriver: Driver<ChartModule.SelectedPointViewItem?> { get }
    var loadingDriver: Driver<Bool> { get }
    var chartInfoDriver: Driver<ChartModule.ViewItem?> { get }
    var errorDriver: Driver<String?> { get }

    func onSelectInterval(at index: Int)
    func start()
    func retry()
}
