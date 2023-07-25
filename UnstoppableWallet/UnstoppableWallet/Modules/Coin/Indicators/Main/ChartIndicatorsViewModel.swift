import Combine
import UIKit
import Chart
import MarketKit

class ChartIndicatorsViewModel {
    private let service: ChartIndicatorsService
    private var cancellables = Set<AnyCancellable>()

    @Published public var viewItems = [ViewItem]()
    @Published public var isLocked: Bool = false

    private let openSettingsSubject = PassthroughSubject<ChartIndicator, Never>()

    init(service: ChartIndicatorsService) {
        self.service = service

        service.$isLocked
                .sink { [weak self] in self?.isLocked = $0 }
                .store(in: &cancellables)

        service.$items
                .sink { [weak self] in self?.sync(items: $0) }
                .store(in: &cancellables)

        isLocked = service.isLocked
        sync(items: service.items)
    }

    private func sync(items: [ChartIndicatorsService.IndicatorItem]) {
        // 1. make sections use all categories for indicators
        viewItems = ChartIndicator.Category.allCases.map { category in
            // 1a get only for each category
            let items = items.filter { $0.indicator.category == category }
            // 1b make array with all indicator names with insufficient data
            let insufficientData = items.compactMap { item in
                if item.insufficientData {
                    return [item.indicator.id, item.indicator.index.description].joined(separator: " ").uppercased()
                }
                return nil
            }

            // 1c calculate viewItems for display
            let indicatorViewItems = items.map {
                IndicatorViewItem(
                        id: $0.indicator.id,
                        index: $0.indicator.index,
                        name: category.name(id: $0.indicator.id, index: $0.indicator.index),
                        image: category.image(index: $0.indicator.index),
                        enabled: $0.indicator.enabled
                )
            }

            return ViewItem(
                    category: category.title,
                    indicators: indicatorViewItems,
                    insufficientData: insufficientData
            )
        }
    }

}

extension ChartIndicatorsViewModel {

    var openSettingsPublisher: AnyPublisher<ChartIndicator, Never> {
        openSettingsSubject.eraseToAnyPublisher()
    }

    func update(indicator: ChartIndicator) {
        service.update(indicator: indicator)
    }

    func saveIndicators() {
        service.saveIndicators()
    }

    func onEdit(viewItem: ChartIndicatorsViewModel.IndicatorViewItem) {
        guard let indicator = service.indicator(id: viewItem.id, index: viewItem.index) else {
            return
        }
        openSettingsSubject.send(indicator)
    }

    func onToggle(viewItem: ChartIndicatorsViewModel.IndicatorViewItem, _ isOn: Bool) {
        service.set(enabled: isOn, id: viewItem.id, index: viewItem.index)
    }

}

extension ChartIndicatorsViewModel {

    struct IndicatorViewItem {
        let id: String
        let index: Int
        let name: String
        let image: UIImage?
        let enabled: Bool
    }

    struct ViewItem {
        let category: String
        let indicators: [IndicatorViewItem]
        let insufficientData: [String]
    }

}

extension ChartIndicator.Category {

    var title: String {
        switch self {
        case .movingAverage: return "chart_indicators.moving_averages".localized
        case .oscillator: return "chart_indicators.oscillators".localized
        }
    }

    func image(index: Int) -> UIImage? {
        switch self {
        case .movingAverage:
            let color = ChartIndicatorFactory.maColors[index % ChartIndicatorFactory.maColors.count]
            return UIImage(named: "chart_type_2_24")?.withTintColor(color)
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
