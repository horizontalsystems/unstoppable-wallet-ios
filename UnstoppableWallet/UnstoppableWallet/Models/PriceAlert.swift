import Foundation

struct PriceAlert {
    let coin: Coin
    var changeState: ChangeState
    var trendState: TrendState

    var changeTopic: String {
        "\(coin.code)_24hour_\(changeState.rawValue)percent"
    }
    var trendTopic: String {
        "\(coin.code)_\(trendState.rawValue)term_trend_change"
    }

    enum ChangeState: Int, CaseIterable {
        case off = 0
        case percent2 = 2
        case percent5 = 5
        case percent10 = 10
    }

    enum TrendState: String, CaseIterable {
        case off = "off"
        case short = "short"
        case long = "long"
    }

}

extension PriceAlert.ChangeState: CustomStringConvertible {

    public var description: String {
        switch self {
        case .off: return "settings_notifications.alert_off".localized
        case .percent2: return "2%"
        case .percent5: return "5%"
        case .percent10: return "10%"
        }
    }

}

extension PriceAlert.TrendState: CustomStringConvertible {

    public var description: String {
        switch self {
        case .off: return "settings_notifications.alert_off".localized
        case .short: return "settings_notifications.trend_short".localized
        case .long: return "settings_notifications.trend_long".localized
        }
    }

}
