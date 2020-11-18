import Foundation
import ObjectMapper

struct GuideCategory: ImmutableMappable {
    private let title: [String: String]
    private let guides: [[String: Guide]]

    init(map: Map) throws {
        title = try map.value("category")
        guides = try map.value("guides", using: GuideTransform())
    }

    func title(language: String, fallbackLanguage: String) -> String? {
        title[language] ?? title[fallbackLanguage]
    }

    func guides(language: String, fallbackLanguage: String) -> [Guide] {
        guides.compactMap { guideMap in
            guideMap[language] ?? guideMap[fallbackLanguage]
        }
    }

}

extension GuideCategory {

    class GuideTransform: TransformType {
        typealias Object = [[String: Guide]]
        typealias JSON = Any

        func transformFromJSON(_ value: Any?) -> [[String: Guide]]? {
            guard let guidesFrom = value as? [[String: Any]] else {
                return nil
            }

            do {
                return try guidesFrom.map { guideFrom in
                    try guideFrom.mapValues { guideJson in
                        try Guide(JSONObject: guideJson)
                    }
                }
            } catch {
                return nil
            }
        }

        func transformToJSON(_ value: [[String: Guide]]?) -> Any? {
            fatalError("transformToJSON(_:) has not been implemented")
        }

    }

}

struct Guide: ImmutableMappable {
    let title: String
    var imageUrl: String?
    let date: Date
    let fileUrl: String

    init(title: String, imageUrl: String? = nil, date: Date = Date(), fileUrl: String) {
        self.title = title
        self.imageUrl = imageUrl
        self.date = date
        self.fileUrl = fileUrl
    }

    init(map: Map) throws {
        title = try map.value("title")
        imageUrl = try map.value("image")
        date = try map.value("updated_at", using: DateTransform())
        fileUrl = try map.value("file")
    }
}

extension Guide {

    class DateTransform: TransformType {
        private static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter
        }()

        typealias Object = Date
        typealias JSON = String

        func transformFromJSON(_ value: Any?) -> Date? {
            guard let value = value as? String else {
                return nil
            }

            return DateTransform.dateFormatter.date(from: value)
        }

        func transformToJSON(_ value: Date?) -> String? {
            fatalError("transformToJSON(_:) has not been implemented")
        }
    }
}
