import Chart
import Combine
import SwiftUI

@MainActor
final class ChartIndicatorSettingsViewModel: ObservableObject {
    @Published private(set) var form: ChartIndicatorSettingsForm

    init(form: ChartIndicatorSettingsForm) {
        self.form = form
    }

    var title: String {
        form.title
    }

    var resetEnabled: Bool {
        !form.isDefault
    }

    var applyEnabled: Bool {
        form.result != nil
    }

    func binding(for field: ChartIndicatorSettingsForm.Field) -> Binding<String> {
        Binding(
            get: { [weak self] in self?.form.text(for: field) ?? "" },
            set: { [weak self] in self?.form.set(text: $0, for: field) }
        )
    }

    var visibleCautions: [ChartIndicatorSettingsForm.Field: String] {
        form.isEdited ? form.cautions : [:]
    }

    func cautionState(for field: ChartIndicatorSettingsForm.Field) -> CautionState {
        guard let text = visibleCautions[field] else {
            return .none
        }

        return .caution(Caution(text: text, type: .error))
    }

    func select(maType: MaIndicator.MaType) {
        form.set(maType: maType)
    }

    func reset() {
        form.reset()
    }

    func apply() -> ChartIndicator? {
        form.result
    }
}
