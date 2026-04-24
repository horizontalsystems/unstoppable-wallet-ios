import Foundation
import UIKit

enum WidgetConfig {
    static var marketApiUrl: String {
        AppEnvironment.config.marketApiUrl
    }

    static var hsProviderApiKey: String? {
        (Bundle.main.object(forInfoDictionaryKey: "HsProviderApiKey") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }
}
