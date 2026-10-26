import Chart
import Combine
import SwiftUI

@MainActor
final class ChartIndicatorsViewModel: ObservableObject {
    private let repository: IChartIndicatorsRepository
    private var indicators: [ChartIndicator]

    @Published private(set) var sections: [IndicatorSection] = []

    init(repository: IChartIndicatorsRepository) {
        self.repository = repository
        indicators = repository.indicators

        syncSections()
    }

    private func syncSections() {
        sections = ChartIndicator.Category.allCases.map { category in
            IndicatorSection(
                id: category,
                title: category.title,
                items: indicators
                    .filter { $0.category == category }
                    .map { indicator in
                        Item(
                            indicatorId: indicator.id,
                            index: indicator.index,
                            name: category.name(id: indicator.id, index: indicator.index),
                            color: category.color(index: indicator.index),
                            enabled: indicator.enabled
                        )
                    }
            )
        }
    }

    private func indicator(id: String, index: Int) -> ChartIndicator? {
        indicators.first { $0.id == id && $0.index == index }
    }

    private static func applyToggle(enabled: Bool, id: String, index: Int, to indicators: [ChartIndicator]) {
        guard let toggled = indicators.first(where: { $0.id == id && $0.index == index }) else {
            return
        }

        toggled.enabled = enabled

        // enabling a single-view indicator disables every other single-view indicator in the same area
        if enabled {
            for indicator in indicators where indicator !== toggled {
                if indicator.onChart == toggled.onChart, indicator.single {
                    indicator.enabled = false
                }
            }
        }
    }
}

extension ChartIndicatorsViewModel {
    func set(enabled: Bool, id: String, index: Int) {
        Self.applyToggle(enabled: enabled, id: id, index: index, to: indicators)
        syncSections()
    }

    func form(id: String, index: Int) -> ChartIndicatorSettingsForm? {
        guard let indicator = indicator(id: id, index: index) else {
            return nil
        }

        return ChartIndicatorSettingsForm(indicator: indicator)
    }

    func update(indicator: ChartIndicator) {
        guard let index = indicators.firstIndex(where: { $0.id == indicator.id && $0.index == indicator.index }) else {
            return
        }

        indicators[index] = indicator
        syncSections()
    }

    func save() {
        repository.set(indicators: indicators)
    }
}

extension ChartIndicatorsViewModel {
    struct IndicatorSection: Identifiable {
        let id: ChartIndicator.Category
        let title: String
        let items: [Item]
    }

    struct Item: Identifiable {
        var id: String {
            "\(indicatorId)-\(index)"
        }

        let indicatorId: String
        let index: Int
        let name: String
        let color: Color?
        let enabled: Bool
    }
}

extension ChartIndicator.Category {
    var title: String {
        switch self {
        case .movingAverage: return "chart_indicators.moving_averages".localized
        case .oscillator: return "chart_indicators.oscillators".localized
        }
    }

    func color(index: Int) -> Color? {
        switch self {
        case .movingAverage:
            return Color(ChartIndicatorFactory.maColors[index % ChartIndicatorFactory.maColors.count])
        case .oscillator: return nil
        }
    }

    func name(id: String, index: Int) -> String {
        switch self {
        case .movingAverage:
            return [id, (index + 1).description].joined(separator: " ").uppercased()
        case .oscillator: return id.uppercased()
        }
    }
}
