import Chart
import Foundation

struct ChartIndicatorSettingsForm: Equatable {
    let indicator: ChartIndicator
    private(set) var kind: Kind

    private let defaultValues: [Field: Int]
    private let originalValues: [Field: Int]
    private let defaultMaType: MaIndicator.MaType?
    private let originalMaType: MaIndicator.MaType?

    init?(indicator: ChartIndicator, defaultIndicators: [ChartIndicator] = ChartIndicatorFactory.defaultIndicators) {
        guard let defaultIndicator = defaultIndicators.first(where: { $0.id == indicator.id && $0.index == indicator.index }) else {
            return nil
        }

        switch (indicator, defaultIndicator) {
        case let (indicator as MaIndicator, defaultIndicator as MaIndicator):
            defaultValues = [.period: defaultIndicator.period]
            originalValues = [.period: indicator.period]
            defaultMaType = defaultIndicator.type
            originalMaType = indicator.type
            kind = .ma(
                type: indicator.type,
                period: Self.initialText(value: indicator.period, defaultValue: defaultIndicator.period)
            )
        case let (indicator as RsiIndicator, defaultIndicator as RsiIndicator):
            defaultValues = [.period: defaultIndicator.period]
            originalValues = [.period: indicator.period]
            defaultMaType = nil
            originalMaType = nil
            kind = .rsi(
                period: Self.initialText(value: indicator.period, defaultValue: defaultIndicator.period)
            )
        case let (indicator as MacdIndicator, defaultIndicator as MacdIndicator):
            defaultValues = [.fast: defaultIndicator.fast, .slow: defaultIndicator.slow, .signal: defaultIndicator.signal]
            originalValues = [.fast: indicator.fast, .slow: indicator.slow, .signal: indicator.signal]
            defaultMaType = nil
            originalMaType = nil
            kind = .macd(
                fast: Self.initialText(value: indicator.fast, defaultValue: defaultIndicator.fast),
                slow: Self.initialText(value: indicator.slow, defaultValue: defaultIndicator.slow),
                signal: Self.initialText(value: indicator.signal, defaultValue: defaultIndicator.signal)
            )
        default:
            return nil
        }

        self.indicator = indicator
    }

    static func isValid(text: String) -> Bool {
        text.isEmpty || (Int(text).map { $0 > 0 } ?? false)
    }

    private static func initialText(value: Int, defaultValue: Int) -> String {
        value == defaultValue ? "" : value.description
    }

    private static func periodError(value: Int) -> String? {
        if value < 0 || value > IndicatorCalculator.maximumPeriod {
            return "chart_indicators.settings.period.error".localized(IndicatorCalculator.maximumPeriod)
        }
        return nil
    }
}

extension ChartIndicatorSettingsForm {
    var title: String {
        switch kind {
        case .ma: return "\(indicator.id) \(indicator.index + 1)"
        case .rsi: return "chart_indicators.settings.rsi.title".localized
        case .macd: return "chart_indicators.settings.macd.title".localized
        }
    }

    var description: String {
        switch kind {
        case .ma: return "chart_indicators.settings.ma.description".localized
        case .rsi: return "chart_indicators.settings.rsi.description".localized
        case .macd: return "chart_indicators.settings.macd.description".localized
        }
    }

    var fields: [Field] {
        switch kind {
        case .ma, .rsi: return [.period]
        case .macd: return [.fast, .slow, .signal]
        }
    }

    func header(for field: Field) -> String {
        switch (kind, field) {
        case (.ma, .period): return "chart_indicators.settings.ma.period_title".localized
        case (.rsi, .period): return "chart_indicators.settings.rsi.period_title".localized
        case (.macd, .fast): return "chart_indicators.settings.macd.fast_period_title".localized
        case (.macd, .slow): return "chart_indicators.settings.macd.slow_period_title".localized
        case (.macd, .signal): return "chart_indicators.settings.macd.signal_period_title".localized
        default: return ""
        }
    }

    func placeholder(for field: Field) -> String {
        defaultValues[field]?.description ?? ""
    }

    func text(for field: Field) -> String {
        switch (kind, field) {
        case let (.ma(_, period), .period): return period
        case let (.rsi(period), .period): return period
        case let (.macd(fast, _, _), .fast): return fast
        case let (.macd(_, slow, _), .slow): return slow
        case let (.macd(_, _, signal), .signal): return signal
        default: return ""
        }
    }

    func value(for field: Field) -> Int {
        let text = text(for: field)

        if !text.isEmpty, Self.isValid(text: text), let value = Int(text) {
            return value
        }
        return defaultValues[field] ?? 0
    }

    var maType: MaIndicator.MaType? {
        if case let .ma(type, _) = kind {
            return type
        }
        return nil
    }

    mutating func set(text: String, for field: Field) {
        switch (kind, field) {
        case let (.ma(type, _), .period): kind = .ma(type: type, period: text)
        case (.rsi, .period): kind = .rsi(period: text)
        case let (.macd(_, slow, signal), .fast): kind = .macd(fast: text, slow: slow, signal: signal)
        case let (.macd(fast, _, signal), .slow): kind = .macd(fast: fast, slow: text, signal: signal)
        case let (.macd(fast, slow, _), .signal): kind = .macd(fast: fast, slow: slow, signal: text)
        default: ()
        }
    }

    mutating func set(maType: MaIndicator.MaType) {
        if case let .ma(_, period) = kind {
            kind = .ma(type: maType, period: period)
        }
    }

    mutating func reset() {
        switch kind {
        case let .ma(type, _): kind = .ma(type: defaultMaType ?? type, period: "")
        case .rsi: kind = .rsi(period: "")
        case .macd: kind = .macd(fast: "", slow: "", signal: "")
        }
    }

    var isDefault: Bool {
        maType == defaultMaType && fields.allSatisfy { value(for: $0) == defaultValues[$0] }
    }

    var isEdited: Bool {
        maType != originalMaType || fields.contains { value(for: $0) != originalValues[$0] }
    }

    var cautions: [Field: String] {
        var cautions = [Field: String]()

        for field in fields {
            if let error = Self.periodError(value: value(for: field)) {
                cautions[field] = error
            }
        }

        if case .macd = kind, value(for: .fast) >= value(for: .slow) {
            let error = "chart_indicators.settings.macd.slow_fast.error".localized
            for field in [Field.fast, .slow] where cautions[field] == nil {
                cautions[field] = error
            }
        }

        return cautions
    }

    var result: ChartIndicator? {
        guard isEdited, cautions.isEmpty else {
            return nil
        }

        switch (kind, indicator) {
        case let (.ma(type, _), indicator as MaIndicator):
            return MaIndicator(
                id: indicator.id,
                index: indicator.index,
                enabled: indicator.enabled,
                period: value(for: .period),
                type: type,
                configuration: indicator.configuration
            )
        case let (.rsi, indicator as RsiIndicator):
            return RsiIndicator(
                id: indicator.id,
                index: indicator.index,
                enabled: indicator.enabled,
                period: value(for: .period),
                configuration: indicator.configuration
            )
        case let (.macd, indicator as MacdIndicator):
            return MacdIndicator(
                id: indicator.id,
                index: indicator.index,
                enabled: indicator.enabled,
                fast: value(for: .fast),
                slow: value(for: .slow),
                signal: value(for: .signal),
                configuration: indicator.configuration
            )
        default:
            return nil
        }
    }
}

extension ChartIndicatorSettingsForm {
    enum Field: Hashable {
        case period
        case fast
        case slow
        case signal
    }

    enum Kind: Equatable {
        case ma(type: MaIndicator.MaType, period: String)
        case rsi(period: String)
        case macd(fast: String, slow: String, signal: String)
    }
}
