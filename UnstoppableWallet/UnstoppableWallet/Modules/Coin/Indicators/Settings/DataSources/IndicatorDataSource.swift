import Combine
import Chart

protocol IIndicatorDataSource {
    var chartIndicator: ChartIndicator { get }
    var notEdited: Bool { get }
    var isDefault: Bool { get }

    var fields: [ChartIndicatorSettingsModule.Field] { get }

    var currentItems: [ChartIndicatorSettingsModule.ValueItem] { get }
    var initialItems: [ChartIndicatorSettingsModule.ValueItem] { get }
    var itemsUpdatedPublisher: AnyPublisher<Void, Never> { get }

    func set(id: String, value: Any?)
    func reset()

    var state: IndicatorDataSource.State { get }
    var stateUpdatedPublisher: AnyPublisher<Void, Never> { get }
}

class IndicatorDataSource {

    enum State {
    case notChanged
    case success(ChartIndicator)
    case failed([Caution])
    }

    struct Caution {
        let id: String
        let error: String
    }

}
