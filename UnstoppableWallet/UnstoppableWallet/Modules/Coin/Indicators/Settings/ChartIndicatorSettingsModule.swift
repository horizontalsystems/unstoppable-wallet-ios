import UIKit
import Chart

class ChartIndicatorSettingsModule {

    static func viewController(indicator: ChartIndicator, onComplete: @escaping (ChartIndicator) -> ()) -> UIViewController? {
        let dataSource: IIndicatorDataSource
        let defaultIndicator = ChartIndicatorFactory
                .defaultIndicators(subscribed: true)
                .first { $0.id == indicator.id && $0.index == indicator.index }
        switch indicator {
        case let indicator as MaIndicator:
            guard let defaultIndicator = defaultIndicator as? MaIndicator else {
                return nil
            }
            dataSource = MaIndicatorDataSource(indicator: indicator, default: defaultIndicator)
        case let indicator as RsiIndicator:
            guard let defaultIndicator = defaultIndicator as? RsiIndicator else {
                return nil
            }
            dataSource = RsiIndicatorDataSource(indicator: indicator, default: defaultIndicator)
        case let indicator as MacdIndicator:
            guard let defaultIndicator = defaultIndicator as? MacdIndicator else {
                return nil
            }
            dataSource = MacdIndicatorDataSource(indicator: indicator, default: defaultIndicator)
        default: return nil
        }

        let viewModel = ChartIndicatorSettingsViewModel(dataSource: dataSource, subscriptionManager: App.shared.subscriptionManager)
        let viewController = ChartIndicatorSettingsViewController(viewModel: viewModel, onComplete: onComplete)

        return viewController
    }

}

extension ChartIndicatorSettingsModule {

    struct ValueItem {
        let id: String
        let value: Any?
    }

    class Field {
        let id: String

        init(id: String) {
            self.id = id
        }
    }

    class TextField: Field {
        let text: String

        init(id: String, text: String) {
            self.text = text

            super.init(id: id)
        }
    }

    struct ListElement {
        let id: Int
        let title: String
        let value: Any
    }

    class ListField: Field {
        let header: String?
        let title: String
        let elements: [ListElement]
        let initial: ListElement

        init(id: String, header: String?, title: String, elements: [ListElement], initial: ListElement) {
            self.header = header
            self.title = title
            self.elements = elements
            self.initial = initial

            super.init(id: id)
        }
    }

    class InputIntegerField: Field {
        let header: String?
        let placeholder: String?
        let initial: String?

        init(id: String, header: String?, placeholder: String?, initial: String?) {
            self.header = header
            self.placeholder = placeholder
            self.initial = initial

            super.init(id: id)
        }
    }

}