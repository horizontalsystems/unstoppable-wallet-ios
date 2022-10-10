import Foundation
import RxSwift
import RxCocoa
import UniswapKit

class SwapDeadlineViewModel {
    private let disposeBag = DisposeBag()

    private let service: UniswapSettingsService
    private let decimalParser: AmountDecimalParser

    public init(service: UniswapSettingsService, decimalParser: AmountDecimalParser) {
        self.service = service
        self.decimalParser = decimalParser
    }

    private func toString(_ value: Double) -> String {
        Decimal(floatLiteral: floor(value / 60)).description
    }

}

extension SwapDeadlineViewModel {

    var placeholder: String {
        toString(TradeOptions.defaultTtl)
    }

    var initialValue: String? {
        guard case let .valid(tradeOptions) = service.state, tradeOptions.ttl != TradeOptions.defaultTtl else {
            return nil
        }

        return toString(tradeOptions.ttl)
    }

    var shortcuts: [InputShortcut] {
        let bounds = service.recommendedDeadlineBounds

        return [
            InputShortcut(title: "swap.advanced_settings.deadline_minute".localized(toString(bounds.lowerBound)), value: toString(bounds.lowerBound)),
            InputShortcut(title: "swap.advanced_settings.deadline_minute".localized(toString(bounds.upperBound)), value: toString(bounds.upperBound)),
        ]
    }

    func onChange(text: String?) {
        guard let value = decimalParser.parseAnyDecimal(from: text) else {
            service.deadline = TradeOptions.defaultTtl
            return
        }

        service.deadline = NSDecimalNumber(decimal: value).doubleValue * 60
    }

    func isValid(text: String) -> Bool {
        guard let amount = decimalParser.parseAnyDecimal(from: text) else {
            return false
        }

        return amount.decimalCount == 0
    }

}
