import Chart
import Foundation
import Testing
@testable import WalletCore

struct ChartIndicatorSettingsFormTests {
    private let rsiId = ChartIndicator.AbstractType.rsi.rawValue
    private let macdId = ChartIndicator.AbstractType.macd.rawValue

    private var periodError: String {
        "chart_indicators.settings.period.error".localized(IndicatorCalculator.maximumPeriod)
    }

    private var orderingError: String {
        "chart_indicators.settings.macd.slow_fast.error".localized
    }

    private func ma(index: Int = 0, enabled: Bool = true, period: Int, type: MaIndicator.MaType = .ema) -> MaIndicator {
        MaIndicator(id: "MA", index: index, enabled: enabled, period: period, type: type, configuration: ChartIndicatorFactory.maConfiguration(index))
    }

    private func rsi(enabled: Bool = true, period: Int) -> RsiIndicator {
        RsiIndicator(id: rsiId, index: 0, enabled: enabled, period: period, configuration: ChartIndicatorFactory.rsiConfiguration)
    }

    private func macd(enabled: Bool = false, fast: Int, slow: Int, signal: Int) -> MacdIndicator {
        MacdIndicator(id: macdId, index: 0, enabled: enabled, fast: fast, slow: slow, signal: signal, configuration: ChartIndicatorFactory.macdConfiguration)
    }

    // MARK: MA

    @Test func maInitialTextsEmptyWhenEqualToDefaults() throws {
        let form = try #require(ChartIndicatorSettingsForm(indicator: ma(period: 9)))

        #expect(form.fields == [.period])
        #expect(form.text(for: .period) == "")
        #expect(form.placeholder(for: .period) == "9")
        #expect(form.maType == .ema)
    }

    @Test func maInitialTextShowsCustomPeriod() throws {
        let form = try #require(ChartIndicatorSettingsForm(indicator: ma(period: 30)))

        #expect(form.text(for: .period) == "30")
        #expect(form.placeholder(for: .period) == "9")
        #expect(form.maType == .ema)
    }

    @Test func emptyTextResolvesToDefault() throws {
        var form = try #require(ChartIndicatorSettingsForm(indicator: ma(period: 9)))

        form.set(text: "30", for: .period)
        #expect(form.value(for: .period) == 30)
        #expect(!form.isDefault)

        form.set(text: "", for: .period)
        #expect(form.value(for: .period) == 9)
        #expect(form.isDefault)
    }

    @Test func maNotEditedHasNoResult() throws {
        let form = try #require(ChartIndicatorSettingsForm(indicator: ma(period: 9)))

        #expect(!form.isEdited)
        #expect(form.result == nil)
        #expect(form.cautions.isEmpty)
        #expect(form.isDefault)
    }

    @Test func maEditedProducesNewIndicatorPreservingIdentity() throws {
        let indicator = ma(index: 1, enabled: false, period: 25)
        var form = try #require(ChartIndicatorSettingsForm(indicator: indicator))

        form.set(text: "30", for: .period)
        form.set(maType: .sma)

        let result = try #require(form.result as? MaIndicator)
        #expect(result.id == indicator.id)
        #expect(result.index == indicator.index)
        #expect(result.enabled == indicator.enabled)
        #expect(result.period == 30)
        #expect(result.type == .sma)
        #expect(result == ma(index: 1, enabled: false, period: 30, type: .sma))
        #expect(result !== indicator)
    }

    @Test func periodAboveMaximumFails() throws {
        var form = try #require(ChartIndicatorSettingsForm(indicator: ma(period: 9)))

        form.set(text: "201", for: .period)
        #expect(form.cautions[.period] == periodError)
        #expect(form.result == nil)

        form.set(text: "200", for: .period)
        #expect(form.cautions.isEmpty)
        #expect((form.result as? MaIndicator)?.period == 200)
    }

    @Test func resetRestoresDefaults() throws {
        var form = try #require(ChartIndicatorSettingsForm(indicator: ma(period: 30, type: .wma)))
        #expect(!form.isDefault)

        form.reset()

        #expect(form.isDefault)
        #expect(form.isEdited)
        #expect(form.text(for: .period) == "")
        let result = try #require(form.result as? MaIndicator)
        #expect(result.period == 9)
        #expect(result.type == .ema)
    }

    // MARK: RSI

    @Test func rsiPeriodFlow() throws {
        var form = try #require(ChartIndicatorSettingsForm(indicator: rsi(period: 12)))
        #expect(form.fields == [.period])
        #expect(form.placeholder(for: .period) == "12")
        #expect(form.maType == nil)

        form.set(text: "14", for: .period)
        let result = try #require(form.result as? RsiIndicator)
        #expect(result == rsi(period: 14))

        form.set(text: "0", for: .period)
        #expect(form.value(for: .period) == 12)
        #expect(form.result == nil)

        form.set(text: "abc", for: .period)
        #expect(form.value(for: .period) == 12)
        #expect(form.result == nil)
    }

    // MARK: MACD

    @Test func macdFastMustBeLessThanSlow() throws {
        var form = try #require(ChartIndicatorSettingsForm(indicator: macd(fast: 12, slow: 26, signal: 9)))
        #expect(form.fields == [.fast, .slow, .signal])

        form.set(text: "26", for: .fast)
        form.set(text: "26", for: .slow)
        #expect(form.cautions[.fast] == orderingError)
        #expect(form.cautions[.slow] == orderingError)
        #expect(form.cautions[.signal] == nil)
        #expect(form.result == nil)

        form.set(text: "12", for: .fast)
        form.set(text: "13", for: .slow)
        #expect(form.cautions.isEmpty)
        #expect(form.result != nil)
    }

    @Test func macdPeriodErrorWinsOverOrderingError() throws {
        var form = try #require(ChartIndicatorSettingsForm(indicator: macd(fast: 12, slow: 26, signal: 9)))

        form.set(text: "300", for: .fast)
        form.set(text: "26", for: .slow)
        #expect(form.cautions[.fast] == periodError)
        #expect(form.cautions[.slow] == orderingError)
        #expect(form.cautions[.signal] == nil)

        form.set(text: "300", for: .signal)
        #expect(form.cautions[.signal] == periodError)
        #expect(form.result == nil)
    }

    @Test func macdResultPreservesIdentity() throws {
        let indicator = macd(enabled: true, fast: 12, slow: 26, signal: 9)
        var form = try #require(ChartIndicatorSettingsForm(indicator: indicator))

        form.set(text: "10", for: .fast)
        form.set(text: "20", for: .slow)
        form.set(text: "5", for: .signal)

        let result = try #require(form.result as? MacdIndicator)
        #expect(result.id == indicator.id)
        #expect(result.index == indicator.index)
        #expect(result.enabled)
        #expect(result.fast == 10)
        #expect(result.slow == 20)
        #expect(result.signal == 5)
        #expect(result == macd(enabled: true, fast: 10, slow: 20, signal: 5))
    }

    // MARK: Unsupported

    @Test func unsupportedIndicatorReturnsNil() {
        #expect(ChartIndicatorSettingsForm(indicator: ma(index: 7, period: 9)) == nil)
    }
}
