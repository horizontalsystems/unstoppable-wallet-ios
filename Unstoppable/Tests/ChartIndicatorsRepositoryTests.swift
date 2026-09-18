import Chart
import Combine
import Foundation
import Testing
@testable import WalletCore

private final class EphemeralUserDefaultsStorage: UserDefaultsStorage {
    private var values = [String: Any]()

    override func value<T>(for key: String) -> T? {
        values[key] as? T
    }

    override func set(value: (some Any)?, for key: String) {
        values[key] = value
    }
}

struct ChartIndicatorsRepositoryTests {
    private func makeRepository(storage: UserDefaultsStorage = EphemeralUserDefaultsStorage()) -> (ChartIndicatorsRepository, LocalStorage) {
        let localStorage = LocalStorage(userDefaultsStorage: storage)
        return (ChartIndicatorsRepository(localStorage: localStorage), localStorage)
    }

    private func customIndicators() -> [ChartIndicator] {
        [
            MaIndicator(id: "MA", index: 0, enabled: false, period: 7, type: .sma, configuration: ChartIndicatorFactory.maConfiguration(0)),
            MaIndicator(id: "MA", index: 1, enabled: true, period: 21, type: .wma, configuration: ChartIndicatorFactory.maConfiguration(1)),
            RsiIndicator(id: "RSI", index: 0, enabled: false, period: 14, configuration: ChartIndicatorFactory.rsiConfiguration),
            MacdIndicator(id: "MACD", index: 0, enabled: true, fast: 5, slow: 13, signal: 3, configuration: ChartIndicatorFactory.macdConfiguration),
        ]
    }

    @Test func emptyStorageReturnsDefaultsAvailableToEveryone() throws {
        let (repository, _) = makeRepository()
        let indicators = repository.indicators

        // Default RSI/MACD ids are the Chart package's AbstractType raw values, unlike the
        // upper-case literals restore(backup:) writes.
        #expect(indicators.map(\.id) == ["MA", "MA", "MA", ChartIndicator.AbstractType.rsi.rawValue, ChartIndicator.AbstractType.macd.rawValue])
        #expect(indicators.map(\.index) == [0, 1, 2, 0, 0])
        #expect(indicators.map(\.enabled) == [true, true, true, true, false])

        let ma = indicators.prefix(3).compactMap { $0 as? MaIndicator }
        #expect(ma.count == 3)
        #expect(ma.map(\.period) == [9, 25, 50])
        #expect(ma.map(\.type) == [.ema, .ema, .ema])
        #expect(ma.allSatisfy { $0.onChart && !$0.single })

        let rsi = try #require(indicators[3] as? RsiIndicator)
        #expect(rsi.period == 12)
        #expect(!rsi.onChart && rsi.single)

        let macd = try #require(indicators[4] as? MacdIndicator)
        #expect(macd.fast == 12)
        #expect(macd.slow == 26)
        #expect(macd.signal == 9)
        #expect(!macd.onChart && macd.single)

        #expect(repository.extendedPointCount == 50)
    }

    @Test func corruptedStoredJsonFallsBackToDefaults() {
        let (repository, localStorage) = makeRepository()
        localStorage.chartIndicators = Data("not json".utf8)

        #expect(repository.indicators == ChartIndicatorFactory.defaultIndicators)
    }

    @Test func settingIndicatorsPersistsAndNotifiesOnlyOnChange() throws {
        let storage = EphemeralUserDefaultsStorage()
        let (repository, localStorage) = makeRepository(storage: storage)

        var updates = 0
        let cancellable = repository.updatedPublisher.sink { updates += 1 }
        defer { cancellable.cancel() }

        repository.set(indicators: ChartIndicatorFactory.defaultIndicators)
        #expect(updates == 0)
        #expect(localStorage.chartIndicators == nil)

        let custom = customIndicators()
        repository.set(indicators: custom)
        #expect(updates == 1)
        #expect(repository.indicators == custom)
        #expect(repository.extendedPointCount == 21)

        let stored = try #require(localStorage.chartIndicators)
        #expect(try JSONDecoder().decode(ChartIndicators.self, from: stored).indicators == custom)

        repository.set(indicators: custom)
        #expect(updates == 1)

        let (reopened, _) = makeRepository(storage: storage)
        #expect(reopened.indicators == custom)
    }

    @Test func backupAndRestoreRoundTripKeepsAllIndicatorKinds() throws {
        let (source, _) = makeRepository()
        source.set(indicators: customIndicators())

        let backup = source.backup
        #expect(backup.ma.map(\.period) == [7, 21])
        #expect(backup.ma.map(\.type) == ["sma", "wma"])
        #expect(backup.ma.map(\.enabled) == [false, true])
        #expect(backup.rsi.map(\.period) == [14])
        #expect(backup.rsi.map(\.enabled) == [false])
        #expect(backup.macd.map { [$0.slow, $0.fast, $0.signal] } == [[13, 5, 3]])
        #expect(backup.macd.map(\.enabled) == [true])

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let transported = try JSONDecoder().decode(ChartIndicatorsRepository.BackupIndicators.self, from: encoder.encode(backup))

        let (target, _) = makeRepository()
        var updates = 0
        let cancellable = target.updatedPublisher.sink { updates += 1 }
        defer { cancellable.cancel() }

        target.restore(backup: transported)
        #expect(updates == 1)
        #expect(target.indicators == customIndicators())
        #expect(try encoder.encode(target.backup) == encoder.encode(backup))
    }
}
