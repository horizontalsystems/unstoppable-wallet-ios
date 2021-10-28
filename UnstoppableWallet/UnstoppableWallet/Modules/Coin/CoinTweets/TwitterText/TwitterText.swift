import Foundation
import UnicodeURL
import CoreFoundation

class TwitterText {
    static let maxURLLength = 4096
    static let maxTCOSlugLength = 40
    static let maxTweetLengthLegacy = 140
    static let transformedURLLength = 23
    static let permillageScaleFactor = 1000

    /// The backend adds http:// for normal links and https to *.twitter.com URLs
    /// (it also rewrites http to https for URLs matching *.twitter.com).
    /// We always add https://. By making the assumption that kURLProtocolLength
    /// is https, the trade off is we'll disallow a http URL that is 4096 characters.
    static let urlProtocolLength = 8

    static func entities(in text: String) -> [Entity] {
        if text.isEmpty {
            return []
        }

        var results: [Entity] = []
        let urls = self.urls(in: text)
        results.append(contentsOf: urls)

        let hashtags = self.hashtags(in: text, with: urls)
        results.append(contentsOf: hashtags)

        let symbols = self.symbols(in: text, with: urls)
        results.append(contentsOf: symbols)

        var addingItems: [Entity] = []

        let mentionsAndLists = mentionsOrLists(in: text)
        for entity in mentionsAndLists {
            let entityRange = entity.range
            var found = false
            for existingEntity in results {
                if NSIntersectionRange(existingEntity.range, entityRange).length > 0 {
                    found = true
                    break
                }
            }
            if !found {
                addingItems.append(entity)
            }
        }

        results.append(contentsOf: addingItems)

        return results
    }

    static func urls(in text: String) -> [Entity] {
        if text.isEmpty {
            return []
        }

        var results: [Entity] = []
        let len = text.utf16.count
        var position = 0
        var allRange = NSMakeRange(0, 0)

        while true {
            position = NSMaxRange(allRange)

            if len <= position {
                break
            }

            guard let urlResult = self.validURLRegexp.firstMatch(in: text, options: [.withoutAnchoringBounds], range: NSMakeRange(position, len - position)) else {
                break
            }

            allRange = urlResult.range

            if urlResult.numberOfRanges < 9 {
                continue
            }

            let nsUrlRange = urlResult.range(at: ValidURLGroup.url.rawValue)
            let nsPrecedingRange = urlResult.range(at: ValidURLGroup.preceding.rawValue)
            let nsProtocolRange = urlResult.range(at: ValidURLGroup.urlProtocol.rawValue)
            let nsDomainRange = urlResult.range(at: ValidURLGroup.domain.rawValue)

            var urlProtocol: String? = nil
            if nsProtocolRange.location != NSNotFound, let protocolRange = Range(nsProtocolRange, in: text) {
                urlProtocol = String(text[protocolRange])
            }

            if urlProtocol == nil || urlProtocol?.count == 0 {
                var preceding: String? = nil
                if nsPrecedingRange.location != NSNotFound, let precedingRange = Range(nsPrecedingRange, in: text) {
                    preceding = String(text[precedingRange])
                }
                if let set = preceding?.rangeOfCharacter(from: self.invalidURLWithoutProtocolPrecedingCharSet, options: [.backwards, .anchored]) {
                    let suffixRange = NSRange(set, in: preceding!)
                    if suffixRange.location != NSNotFound {
                        continue
                    }
                }
            }

            var url: String? = nil
            if nsUrlRange.location != NSNotFound, let urlRange = Range(nsUrlRange, in: text) {
                url = String(text[urlRange])
            }

            var host: String? = nil
            if nsDomainRange.location != NSNotFound, let domainRange = Range(nsDomainRange, in: text) {
                host = String(text[domainRange])
            }

            let start = nsUrlRange.location
            var end = NSMaxRange(nsUrlRange)

            let tcoResult: NSTextCheckingResult?
            if let url = url {
                tcoResult = self.validTCOURLRegexp.firstMatch(in: url, options: [], range: NSMakeRange(0, url.utf16.count))
            } else {
                tcoResult = nil
            }

            if let tcoResult = tcoResult, tcoResult.numberOfRanges >= 2 {
                let nsTcoRange = tcoResult.range(at: 0)
                let nsTcoUrlSlugRange = tcoResult.range(at: 1)

                if nsTcoRange.location == NSNotFound || nsTcoUrlSlugRange.location == NSNotFound {
                    continue
                }

                guard let tcoUrlSlugRange = Range(nsTcoUrlSlugRange, in: text) else {
                    continue
                }

                let tcoUrlSlug = String(text[tcoUrlSlugRange])

                if tcoUrlSlug.utf16.count > TwitterText.maxTCOSlugLength {
                    continue
                } else {
                    if let unwrappedUrl = url, let tcoRange = Range(nsTcoRange, in: unwrappedUrl) {
                        url = String(unwrappedUrl[tcoRange])
                    }
                    end = start + url!.utf16.count
                }
            }

            if isValidHostAndLength(urlLength: url!.utf16.count, urlProtocol: urlProtocol, host: host) {
                let entity = Entity(withType: .url, range: NSMakeRange(start, end - start))
                results.append(entity)
                allRange = entity.range
            }
        }

        return results
    }

    static func hashtags(in text: String, checkingURLOverlap: Bool) -> [Entity] {
        if text.isEmpty {
            return []
        }

        var urls: [Entity] = []
        if checkingURLOverlap {
            urls = self.urls(in: text)
        }

        return self.hashtags(in: text, with: urls)
    }

    static func hashtags(in text: String, with urlEntities: [Entity]) -> [Entity] {
        if text.isEmpty {
            return []
        }

        var results: [Entity] = []
        let len = text.utf16.count
        var position = 0

        while true {
            let matchResult = self.validHashtagRegexp.firstMatch(in: text, options: [.withoutAnchoringBounds], range: NSMakeRange(position, len - position))

            guard let result = matchResult, result.numberOfRanges > 1 else {
                break
            }

            let hashtagRange = result.range(at: 1)
            var matchOk = true

            for urlEntity in urlEntities {
                if NSIntersectionRange(urlEntity.range, hashtagRange).length > 0 {
                    matchOk = false
                    break
                }
            }

            if matchOk {
                let afterStart = NSMaxRange(hashtagRange)
                if afterStart < len {
                    let endMatchRange = self.endHashtagRegexp.rangeOfFirstMatch(in: text, options: [], range: NSMakeRange(afterStart, len - afterStart))
                    if endMatchRange.location != NSNotFound {
                        matchOk = false
                    }
                }

                if matchOk {
                    let entity = Entity(withType: .hashtag, range: hashtagRange)
                    results.append(entity)
                }
            }

            position = NSMaxRange(result.range)
        }

        return results
    }

    static func symbols(in text: String, checkingURLOverlap: Bool) -> [Entity] {
        if text.isEmpty {
            return []
        }

        var urls: [Entity] = []
        if checkingURLOverlap {
            urls = self.urls(in: text)
        }

        return symbols(in: text, with: urls)
    }

    static func symbols(in text: String, with urlEntities: [Entity]) -> [Entity] {
        if text.isEmpty {
            return []
        }

        var results: [Entity] = []
        let len = text.utf16.count
        var position = 0

        while true {
            let matchResult = self.validSymbolRegexp.firstMatch(in: text, options: [.withoutAnchoringBounds], range: NSMakeRange(position, len - position))

            guard let result = matchResult, result.numberOfRanges >= 2 else {
                break
            }

            let symbolRange = result.range(at: 1)
            var matchOk = true

            for urlEntity in urlEntities {
                if NSIntersectionRange(urlEntity.range, symbolRange).length > 0 {
                    matchOk = false
                    break
                }
            }

            if matchOk {
                let entity = Entity(withType: .symbol, range: symbolRange)
                results.append(entity)
            }

            position = NSMaxRange(result.range)
        }

        return results
    }

    static func mentionedScreenNames(in text: String) -> [Entity] {
        if text.isEmpty {
            return []
        }

        let mentionsOrLists = self.mentionsOrLists(in: text)
        var results: [Entity] = []

        for entity in mentionsOrLists {
            if entity.type == .screenName {
                results.append(entity)
            }
        }

        return results
    }

    static func mentionsOrLists(in text: String) -> [Entity] {
        if text.isEmpty {
            return []
        }

        var results: [Entity] = []
        let len = text.utf16.count
        var position = 0

        while true {
            let matchResult = self.validMentionOrListRegexp.firstMatch(in: text, options: [.withoutAnchoringBounds], range: NSMakeRange(position, len - position))

            guard let result = matchResult, result.numberOfRanges >= 5 else {
                break
            }

            let allRange = result.range
            var end = NSMaxRange(allRange)

            let endMentionRange = self.endMentionRegexp.rangeOfFirstMatch(in: text, options: [], range: NSMakeRange(end, len - end))
            if endMentionRange.location == NSNotFound {
                let atSignRange = result.range(at: 2)
                let screenNameRange = result.range(at: 3)
                let listNameRange = result.range(at: 4)

                if listNameRange.location == NSNotFound {
                    let entity = Entity(withType: .screenName, range: NSMakeRange(atSignRange.location, NSMaxRange(screenNameRange) - atSignRange.location))
                    results.append(entity)
                } else {
                    let entity = Entity(withType: .listname, range: NSMakeRange(atSignRange.location, NSMaxRange(listNameRange) - atSignRange.location))
                    results.append(entity)
                }
            } else {
                end += 1
            }

            position = end
        }

        return results
    }

    static func repliedScreenName(in text: String) -> Entity? {
        if text.isEmpty {
            return nil
        }

        let len = text.utf16.count
        let matchResult = self.validReplyRegexp.firstMatch(in: text, options: [.withoutAnchoringBounds, .anchored], range: NSMakeRange(0, len))

        guard let result = matchResult, result.numberOfRanges >= 2 else {
            return nil
        }

        let replyRange = result.range(at: 1)
        let replyEnd = NSMaxRange(replyRange)
        let endMentionRange = self.endMentionRegexp.rangeOfFirstMatch(in: text, options: [], range: NSMakeRange(replyEnd, len - replyEnd))

        if endMentionRange.location != NSNotFound {
            return nil
        }

        return Entity(withType: .screenName, range: replyRange)
    }

    static func validHashtagBoundaryCharacterSet() -> CharacterSet {
        var set: CharacterSet = .letters
        set.formUnion(.decimalDigits)
        set.formUnion(CharacterSet(charactersIn: Regexp.TWHashtagSpecialChars + "&"))

        return set.inverted
    }

    static func tweetLength(text: String) -> Int {
        return self.tweetLength(text: text, transformedURLLength: transformedURLLength)
    }

    static func tweetLength(text: String, transformedURLLength: Int) -> Int {
        // Use Unicode Normalization Form Canonical Composition to calculate tweet text length
        let text = text.precomposedStringWithCanonicalMapping

        if text.isEmpty {
            return 0
        }

        // Remove URLs from text and add t.co length
        var string = text
        var urlLengthOffset = 0
        let urlEntities = urls(in: text)

        for urlEntity in urlEntities.reversed() {
            let entity = urlEntity
            let urlRange = entity.range
            urlLengthOffset += transformedURLLength

            let mutableString = NSMutableString(string: string)
            mutableString.deleteCharacters(in: urlRange)
            string = mutableString as String
        }

        let len = string.count
        var charCount = len + urlLengthOffset

        if len > 0 {
            var buffer: [UniChar] = Array.init(repeating: UniChar(), count: len)

            let mutableString = NSMutableString(string: string)
            mutableString.getCharacters(&buffer, range: NSMakeRange(0, len))

            for index in 0..<len {
                let c = buffer[index]
                if CFStringIsSurrogateHighCharacter(c) {
                    if index + 1 < len {
                        let d = buffer[index + 1]
                        if CFStringIsSurrogateHighCharacter(d) {
                            charCount -= 1
                        }
                    }
                }
            }
        }

        return charCount
    }

    static func remainingCharacterCount(text: String) -> Int {
        self.remainingCharacterCount(text: text, transformedURLLength: transformedURLLength)
    }

    static func remainingCharacterCount(text: String, transformedURLLength: Int) -> Int {
        maxTweetLengthLegacy - self.tweetLength(text: text, transformedURLLength: transformedURLLength)
    }

    // MARK: - Private Methods

    internal static let invalidCharacterRegexp = try! NSRegularExpression(pattern: Regexp.TWUInvalidCharactersPattern, options: .caseInsensitive)

    private static let validGTLDRegexp = try! NSRegularExpression(pattern: Regexp.TWUValidGTLD, options: .caseInsensitive)

    private static let validURLRegexp = try! NSRegularExpression(pattern: Regexp.TWUValidURLPatternString, options: .caseInsensitive)

    private static let validTCOURLRegexp = try! NSRegularExpression(pattern: Regexp.TWUValidTCOURL, options: .caseInsensitive)

    private static let validHashtagRegexp = try! NSRegularExpression(pattern: Regexp.TWUValidHashtag, options: .caseInsensitive)

    private static let endHashtagRegexp = try! NSRegularExpression(pattern: Regexp.TWUEndHashTagMatch, options: .caseInsensitive)

    private static let validSymbolRegexp = try! NSRegularExpression(pattern: Regexp.TWUValidSymbol, options: .caseInsensitive)

    private static let validMentionOrListRegexp = try! NSRegularExpression(pattern: Regexp.TWUValidMentionOrList, options: .caseInsensitive)

    private static let validReplyRegexp = try! NSRegularExpression(pattern: Regexp.TWUValidReply, options: .caseInsensitive)

    private static let endMentionRegexp = try! NSRegularExpression(pattern: Regexp.TWUEndMentionMatch, options: .caseInsensitive)

    private static let invalidURLWithoutProtocolPrecedingCharSet: CharacterSet = {
        CharacterSet.init(charactersIn: "-_./")
    }()

    private static func isValidHostAndLength(urlLength: Int, urlProtocol: String?, host: String?) -> Bool {
        guard var host = host else {
            return false
        }
        var urlLength = urlLength
        var hostUrl: URL?
        do {
            hostUrl = try URL(unicodeUrlString: host)
        } catch let error as UnicodeURLConvertError {
            if error.error == .invalidDNSLength {
                return false
            } else {
                hostUrl = URL(string: host)
            }
        } catch {
        }

        if hostUrl == nil {
            hostUrl = URL.init(string: host)
        }

        guard let url = hostUrl else {
            return false
        }

        // TODO: Make sure this is correct
        //        NSURL *url = [NSURL URLWithUnicodeString:host error:&error];
        //        if (error) {
        //            if (error.code == IFUnicodeURLConvertErrorInvalidDNSLength) {
        //                // If the error is specifically IFUnicodeURLConvertErrorInvalidDNSLength,
        //                // just return a false result. NSURL will happily create a URL for a host
        //                // with labels > 63 characters (radar 35802213).
        //                return NO;
        //            } else {
        //                // Attempt to create a NSURL object. We may have received an error from
        //                // URLWithUnicodeString above because the input is not valid for punycode
        //                // conversion (example: non-LDH characters are invalid and will trigger
        //                // an error with code == IFUnicodeURLConvertErrorSTD3NonLDH but may be
        //                // allowed normally per RFC 1035.
        //                url = [NSURL URLWithString:host];
        //            }
        //        }

        let originalHostLength = host.count

        host = url.absoluteString
        let updatedHostLength = host.utf16.count
        if updatedHostLength == 0 {
            return false
        } else if updatedHostLength > originalHostLength {
            urlLength += (updatedHostLength - originalHostLength)
        }

        // Because the backend always adds https:// if we're missing a protocol, add this length
        // back in when checking vs. our maximum allowed length of a URL, if necessary.
        var urlLengthWithProtocol = urlLength
        if urlProtocol == nil {
            urlLengthWithProtocol += TwitterText.urlProtocolLength
        }

        return urlLengthWithProtocol <= maxURLLength
    }

    class Entity {
        var type: EntityType
        var range: NSRange

        init(withType type: EntityType, range: NSRange) {
            self.type = type
            self.range = range
        }
    }

    enum EntityType: Int {
        case url
        case screenName
        case hashtag
        case listname
        case symbol
        case tweetChar
        case tweetEmojiChar
    }

    enum ValidURLGroup: Int {
        case all = 1
        case preceding
        case url
        case urlProtocol
        case domain
        case port
        case path
        case queryString
    }

    enum Regexp {
        static let TWUControlCharacters = "\\u0009-\\u000D"
        static let TWUSpace = "\\u0020"
        static let TWUControl85 = "\\u0085"
        static let TWUNoBreakSpace = "\\u00A0"
        static let TWUOghamBreakSpace = "\\u1680"
        static let TWUMongolianVowelSeparator = "\\u180E"
        static let TWUWhiteSpaces = "\\u2000-\\u200A"
        static let TWULineSeparator = "\\u2028"
        static let TWUParagraphSeparator = "\\u2029"
        static let TWUNarrowNoBreakSpace = "\\u202F"
        static let TWUMediumMathematicalSpace = "\\u205F"
        static let TWUIdeographicSpace = "\\u3000"

        static let TWUUnicodeSpaces = "\(TWUControlCharacters)\(TWUSpace)\(TWUControl85)"
                + "\(TWUNoBreakSpace)\(TWUOghamBreakSpace)\(TWUMongolianVowelSeparator)"
                + "\(TWUWhiteSpaces)\(TWULineSeparator)\(TWUParagraphSeparator)"
                + "\(TWUNarrowNoBreakSpace)\(TWUMediumMathematicalSpace)\(TWUIdeographicSpace)"

        static let TWUUnicodeALM = "\\u061C"
        static let TWUUnicodeLRM = "\\u200E"
        static let TWUUnicodeRLM = "\\u200F"
        static let TWUUnicodeLRE = "\\u202A"
        static let TWUUnicodeRLE = "\\u202B"
        static let TWUUnicodePDF = "\\u202C"
        static let TWUUnicodeLRO = "\\u202D"
        static let TWUUnicodeRLO = "\\u202E"
        static let TWUUnicodeLRI = "\\u2066"
        static let TWUUnicodeRLI = "\\u2067"
        static let TWUUnicodeFSI = "\\u2068"
        static let TWUUnicodePDI = "\\u2069"

        static let TWUUnicodeDirectionalCharacters = "\(TWUUnicodeALM)\(TWUUnicodeLRM)"
                + "\(TWUUnicodeLRE)\(TWUUnicodeRLE)\(TWUUnicodePDF)\(TWUUnicodeLRO)"
                + "\(TWUUnicodeRLO)\(TWUUnicodeLRI)\(TWUUnicodeRLI)\(TWUUnicodeFSI)\(TWUUnicodePDI)"

        static let TWUInvalidCharacters = "\\uFFFE\\uFEFF\\uFFFF"
        static let TWUInvalidCharactersPattern = "[\(TWUInvalidCharacters)]"

        static let TWULatinAccents = "\\u00C0-\\u00D6\\u00D8-\\u00F6\\u00F8-\\u00FF\\u0100-\\u024F\\u0253-\\u0254\\u0256-\\u0257\\u0259\\u025b\\u0263\\u0268\\u026F\\u0272\\u0289\\u02BB\\u1E00-\\u1EFF"

        // MARK: - Hashtag

        static let TWUPunctuationChars = "-_!\"#$%&'\\(\\)*+,./:;<=>?@\\[\\]^`\\{|}~"
        static let TWUPunctuationCharsWithoutHyphen = "_!\"#$%&'\\(\\)*+,./:;<=>?@\\[\\]^`\\{|}~"
        static let TWUPunctuationCharsWithoutHyphenAndUnderscore = "!\"#$%&'\\(\\)*+,./:;<=>?@\\[\\]^`\\{|}~"

        static let TWHashtagAlpha = "[\\p{L}\\p{M}]"
        static let TWHashtagSpecialChars = "_\\u200c\\u200d\\ua67e\\u05be\\u05f3\\u05f4\\uff5e\\u301c\\u309b\\u309c\\u30a0\\u30fb\\u3003\\u0f0b\\u0f0c\\u00b7"
        static let TWUHashtagAlphanumeric = "[\\p{L}\\p{M}\\p{Nd}\(TWHashtagSpecialChars)]"
        static let TWUHashtagBoundaryInvalidChars = "&\\p{L}\\p{M}\\p{Nd}\(TWHashtagSpecialChars)"
        static let TWUHashtagBoundary = "^|\\ufe0e|\\ufe0f|$|[^\(TWUHashtagBoundaryInvalidChars)]"

        static let TWUValidHashtag = "(?:\(TWUHashtagBoundary))([#＃](?!\\ufe0f|\\u20e3)\(TWUHashtagAlphanumeric)*\(TWHashtagAlpha)\(TWUHashtagAlphanumeric)*)"

        static let TWUEndHashTagMatch = "\\A(?:[#＃]|://)"

        // MARK: - Symbol (Cashtag)

        static let TWUSymbol = "[a-z]{1,6}(?:[._][a-z]{1,2})?"
        static let TWUValidSymbol = "(?:^|[\(TWUUnicodeSpaces)\(TWUUnicodeDirectionalCharacters)])"
                + "(\\$\(TWUSymbol))(?=$|\\s|[\(TWUPunctuationChars)])"

        // MARK: - Mention and list name

        static let TWUValidMentionPrecedingChars = "(?:[^a-z0-9_!#$%&*@＠]|^|(?:^|[^a-z0-9_+~.-])RT:?)"
        static let TWUAtSigns = "[@＠]"
        static let TWUValidUsername = "\\A\(TWUAtSigns)[a-z0-9_]{1,20}\\z"
        static let TWUValidList = "\\A\(TWUAtSigns)[a-z0-9_]{1,20}/[a-z][a-z0-9_\\-]{0,24}\\z"

        static let TWUValidMentionOrList = "(\(TWUValidMentionPrecedingChars))"
                + "(\(TWUAtSigns))([a-z0-9_]{1,20})(/[a-z][a-z0-9_\\-]{0,24})?"

        static let TWUValidReply = "\\A(?:[\(TWUUnicodeSpaces)"
                + "\(TWUUnicodeDirectionalCharacters)])*\(TWUAtSigns)([a-z0-9_]{1,20})"

        static let TWUEndMentionMatch = "\\A(?:\(TWUAtSigns)|[\(TWULatinAccents)]|://)"

        // MARK: - URL

        static let TWUValidURLPrecedingChars = "(?:[^a-z0-9@＠$#＃\(TWUInvalidCharacters)]|[\(TWUUnicodeDirectionalCharacters)]|^)"

        /// These patterns extract domains that are ascii+latin only. We separately check
        /// for unencoded domains with unicode characters elsewhere.
        static let TWUValidURLCharacters = "[a-z0-9\(TWULatinAccents)]"
        static let TWUValidURLSubdomain = "(?>(?:\(TWUValidURLCharacters)"
                + "[\(TWUValidURLCharacters)\\-_]{0,255})?\(TWUValidURLCharacters)\\.)"

        static let TWUValidURLDomain = "(?:(?:\(TWUValidURLCharacters)"
                + "[\(TWUValidURLCharacters)\\-]{0,255})?\(TWUValidURLCharacters)\\.)"

        /// Used to extract domains that contain unencoded unicode.
        static let TWUValidURLUnicodeCharacters = "[^\(TWUPunctuationChars)\\s\\p{Z}\\p{InGeneralPunctuation}]"

        static let TWUValidURLUnicodeDomain = "(?:(?:\(TWUValidURLUnicodeCharacters)"
                + "[\(TWUValidURLUnicodeCharacters)\\-]{0,255})?\(TWUValidURLUnicodeCharacters)\\.)"

        static let TWUValidPunycode = "(?:xn--[-0-9a-z]+)"

        static let TWUValidDomain = "(?:\(TWUValidURLSubdomain)*\(TWUValidURLDomain)"
                + "(?:\(TWUValidGTLD)|\(TWUValidCCTLD)|\(TWUValidPunycode))"
                + ")|(?:(?<=https?://)(?:(?:\(TWUValidURLDomain)\(TWUValidCCTLD))"
                + "|(?:\(TWUValidURLUnicodeDomain){0,255}\(TWUValidURLUnicodeDomain)"
                + "(?:\(TWUValidGTLD)|\(TWUValidCCTLD)))))|(?:"
                + "\(TWUValidURLDomain)\(TWUValidCCTLD)(?=/))"

        static let TWUValidPortNumber = "[0-9]++"
        static let TWUValidGeneralURLPathChars = "[a-z\\p{Cyrillic}0-9!\\*';:=+,.$/%#\\[\\]\\-\\u2013_~&|@\(TWULatinAccents)]"

        static let TWUValidURLBalancedParens = "\\((?:\(TWUValidGeneralURLPathChars)+"
                + "|(?:\(TWUValidGeneralURLPathChars)*\\(\(TWUValidGeneralURLPathChars)+"
                + "\\)\(TWUValidGeneralURLPathChars)*))\\)"

        static let TWUValidURLPathEndingChars = "[a-z\\p{Cyrillic}0-9=_#/+\\-\(TWULatinAccents)]|(?:\(TWUValidURLBalancedParens))"

        static let TWUValidPath = "(?:(?:\(TWUValidGeneralURLPathChars)*"
                + "(?:\(TWUValidURLBalancedParens)\(TWUValidGeneralURLPathChars)*)*"
                + "\(TWUValidURLPathEndingChars))|(?:@\(TWUValidGeneralURLPathChars)+/))"

        static let TWUValidURLQueryChars = "[a-z0-9!?*'\\(\\);:&=+$/%#\\[\\]\\-_\\.,~|@]"
        static let TWUValidURLQueryEndingChars = "[a-z0-9\\-_&=#/]"

        static let TWUValidURLPatternString = "((\(TWUValidURLPrecedingChars))"
                + "((https?://)?(\(TWUValidDomain))(?::(\(TWUValidPortNumber)))?"
                + "(/\(TWUValidPath)*+)?(\\?\(TWUValidURLQueryChars)*"
                + "\(TWUValidURLQueryEndingChars))?))"

        static let TWUValidGTLD = "(?:(?:"
                + "삼성|닷컴|닷넷|香格里拉|餐厅|食品|飞利浦|電訊盈科|集团|通販|购物|谷歌|诺基亚|联通|网络|网站|网店|网址|组织机构|移动|珠宝|点看|游戏|淡马锡|机构|書籍|时尚|新闻|政府|政务|"
                + "招聘|手表|手机|我爱你|慈善|微博|广东|工行|家電|娱乐|天主教|大拿|大众汽车|在线|嘉里大酒店|嘉里|商标|商店|商城|公益|公司|八卦|健康|信息|佛山|企业|中文网|中信|世界|ポイント|"
                + "ファッション|セール|ストア|コム|グーグル|クラウド|みんな|คอม|संगठन|नेट|कॉम|همراه|موقع|موبايلي|كوم|كاثوليك|عرب|شبكة|بيتك|بازار|"
                + "العليان|ارامكو|اتصالات|ابوظبي|קום|сайт|рус|орг|онлайн|москва|ком|католик|дети|zuerich|zone|zippo|zip|"
                + "zero|zara|zappos|yun|youtube|you|yokohama|yoga|yodobashi|yandex|yamaxun|yahoo|yachts|xyz|xxx|xperia|"
                + "xin|xihuan|xfinity|xerox|xbox|wtf|wtc|wow|world|works|work|woodside|wolterskluwer|wme|winners|wine|"
                + "windows|win|williamhill|wiki|wien|whoswho|weir|weibo|wedding|wed|website|weber|webcam|weatherchannel|"
                + "weather|watches|watch|warman|wanggou|wang|walter|walmart|wales|vuelos|voyage|voto|voting|vote|volvo|"
                + "volkswagen|vodka|vlaanderen|vivo|viva|vistaprint|vista|vision|visa|virgin|vip|vin|villas|viking|vig|"
                + "video|viajes|vet|versicherung|vermögensberatung|vermögensberater|verisign|ventures|vegas|vanguard|"
                + "vana|vacations|ups|uol|uno|university|unicom|uconnect|ubs|ubank|tvs|tushu|tunes|tui|tube|trv|trust|"
                + "travelersinsurance|travelers|travelchannel|travel|training|trading|trade|toys|toyota|town|tours|"
                + "total|toshiba|toray|top|tools|tokyo|today|tmall|tkmaxx|tjx|tjmaxx|tirol|tires|tips|tiffany|tienda|"
                + "tickets|tiaa|theatre|theater|thd|teva|tennis|temasek|telefonica|telecity|tel|technology|tech|team|"
                + "tdk|tci|taxi|tax|tattoo|tatar|tatamotors|target|taobao|talk|taipei|tab|systems|symantec|sydney|swiss|"
                + "swiftcover|swatch|suzuki|surgery|surf|support|supply|supplies|sucks|style|study|studio|stream|store|"
                + "storage|stockholm|stcgroup|stc|statoil|statefarm|statebank|starhub|star|staples|stada|srt|srl|"
                + "spreadbetting|spot|sport|spiegel|space|soy|sony|song|solutions|solar|sohu|software|softbank|social|"
                + "soccer|sncf|smile|smart|sling|skype|sky|skin|ski|site|singles|sina|silk|shriram|showtime|show|shouji|"
                + "shopping|shop|shoes|shiksha|shia|shell|shaw|sharp|shangrila|sfr|sexy|sex|sew|seven|ses|services|"
                + "sener|select|seek|security|secure|seat|search|scot|scor|scjohnson|science|schwarz|schule|school|"
                + "scholarships|schmidt|schaeffler|scb|sca|sbs|sbi|saxo|save|sas|sarl|sapo|sap|sanofi|sandvikcoromant|"
                + "sandvik|samsung|samsclub|salon|sale|sakura|safety|safe|saarland|ryukyu|rwe|run|ruhr|rugby|rsvp|room|"
                + "rogers|rodeo|rocks|rocher|rmit|rip|rio|ril|rightathome|ricoh|richardli|rich|rexroth|reviews|review|"
                + "restaurant|rest|republican|report|repair|rentals|rent|ren|reliance|reit|reisen|reise|rehab|"
                + "redumbrella|redstone|red|recipes|realty|realtor|realestate|read|raid|radio|racing|qvc|quest|quebec|"
                + "qpon|pwc|pub|prudential|pru|protection|property|properties|promo|progressive|prof|productions|prod|"
                + "pro|prime|press|praxi|pramerica|post|porn|politie|poker|pohl|pnc|plus|plumbing|playstation|play|"
                + "place|pizza|pioneer|pink|ping|pin|pid|pictures|pictet|pics|piaget|physio|photos|photography|photo|"
                + "phone|philips|phd|pharmacy|pfizer|pet|pccw|pay|passagens|party|parts|partners|pars|paris|panerai|"
                + "panasonic|pamperedchef|page|ovh|ott|otsuka|osaka|origins|orientexpress|organic|org|orange|oracle|"
                + "open|ooo|onyourside|online|onl|ong|one|omega|ollo|oldnavy|olayangroup|olayan|okinawa|office|off|"
                + "observer|obi|nyc|ntt|nrw|nra|nowtv|nowruz|now|norton|northwesternmutual|nokia|nissay|nissan|ninja|"
                + "nikon|nike|nico|nhk|ngo|nfl|nexus|nextdirect|next|news|newholland|new|neustar|network|netflix|"
                + "netbank|net|nec|nba|navy|natura|nationwide|name|nagoya|nadex|nab|mutuelle|mutual|museum|mtr|mtpc|mtn|"
                + "msd|movistar|movie|mov|motorcycles|moto|moscow|mortgage|mormon|mopar|montblanc|monster|money|monash|"
                + "mom|moi|moe|moda|mobily|mobile|mobi|mma|mls|mlb|mitsubishi|mit|mint|mini|mil|microsoft|miami|metlife|"
                + "merckmsd|meo|menu|men|memorial|meme|melbourne|meet|media|med|mckinsey|mcdonalds|mcd|mba|mattel|"
                + "maserati|marshalls|marriott|markets|marketing|market|map|mango|management|man|makeup|maison|maif|"
                + "madrid|macys|luxury|luxe|lupin|lundbeck|ltda|ltd|lplfinancial|lpl|love|lotto|lotte|london|lol|loft|"
                + "locus|locker|loans|loan|llp|llc|lixil|living|live|lipsy|link|linde|lincoln|limo|limited|lilly|like|"
                + "lighting|lifestyle|lifeinsurance|life|lidl|liaison|lgbt|lexus|lego|legal|lefrak|leclerc|lease|lds|"
                + "lawyer|law|latrobe|latino|lat|lasalle|lanxess|landrover|land|lancome|lancia|lancaster|lamer|"
                + "lamborghini|ladbrokes|lacaixa|kyoto|kuokgroup|kred|krd|kpn|kpmg|kosher|komatsu|koeln|kiwi|kitchen|"
                + "kindle|kinder|kim|kia|kfh|kerryproperties|kerrylogistics|kerryhotels|kddi|kaufen|juniper|juegos|jprs|"
                + "jpmorgan|joy|jot|joburg|jobs|jnj|jmp|jll|jlc|jio|jewelry|jetzt|jeep|jcp|jcb|java|jaguar|iwc|iveco|"
                + "itv|itau|istanbul|ist|ismaili|iselect|irish|ipiranga|investments|intuit|international|intel|int|"
                + "insure|insurance|institute|ink|ing|info|infiniti|industries|inc|immobilien|immo|imdb|imamat|ikano|"
                + "iinet|ifm|ieee|icu|ice|icbc|ibm|hyundai|hyatt|hughes|htc|hsbc|how|house|hotmail|hotels|hoteles|hot|"
                + "hosting|host|hospital|horse|honeywell|honda|homesense|homes|homegoods|homedepot|holiday|holdings|"
                + "hockey|hkt|hiv|hitachi|hisamitsu|hiphop|hgtv|hermes|here|helsinki|help|healthcare|health|hdfcbank|"
                + "hdfc|hbo|haus|hangout|hamburg|hair|guru|guitars|guide|guge|gucci|guardian|group|grocery|gripe|green|"
                + "gratis|graphics|grainger|gov|got|gop|google|goog|goodyear|goodhands|goo|golf|goldpoint|gold|godaddy|"
                + "gmx|gmo|gmbh|gmail|globo|global|gle|glass|glade|giving|gives|gifts|gift|ggee|george|genting|gent|gea|"
                + "gdn|gbiz|gay|garden|gap|games|game|gallup|gallo|gallery|gal|fyi|futbol|furniture|fund|fun|fujixerox|"
                + "fujitsu|ftr|frontier|frontdoor|frogans|frl|fresenius|free|fox|foundation|forum|forsale|forex|ford|"
                + "football|foodnetwork|food|foo|fly|flsmidth|flowers|florist|flir|flights|flickr|fitness|fit|fishing|"
                + "fish|firmdale|firestone|fire|financial|finance|final|film|fido|fidelity|fiat|ferrero|ferrari|"
                + "feedback|fedex|fast|fashion|farmers|farm|fans|fan|family|faith|fairwinds|fail|fage|extraspace|"
                + "express|exposed|expert|exchange|everbank|events|eus|eurovision|etisalat|esurance|estate|esq|erni|"
                + "ericsson|equipment|epson|epost|enterprises|engineering|engineer|energy|emerck|email|education|edu|"
                + "edeka|eco|eat|earth|dvr|dvag|durban|dupont|duns|dunlop|duck|dubai|dtv|drive|download|dot|doosan|"
                + "domains|doha|dog|dodge|doctor|docs|dnp|diy|dish|discover|discount|directory|direct|digital|diet|"
                + "diamonds|dhl|dev|design|desi|dentist|dental|democrat|delta|deloitte|dell|delivery|degree|deals|"
                + "dealer|deal|dds|dclk|day|datsun|dating|date|data|dance|dad|dabur|cyou|cymru|cuisinella|csc|cruises|"
                + "cruise|crs|crown|cricket|creditunion|creditcard|credit|cpa|courses|coupons|coupon|country|corsica|"
                + "coop|cool|cookingchannel|cooking|contractors|contact|consulting|construction|condos|comsec|computer|"
                + "compare|company|community|commbank|comcast|com|cologne|college|coffee|codes|coach|clubmed|club|cloud|"
                + "clothing|clinique|clinic|click|cleaning|claims|cityeats|city|citic|citi|citadel|cisco|circle|"
                + "cipriani|church|chrysler|chrome|christmas|chloe|chintai|cheap|chat|chase|charity|channel|chanel|cfd|"
                + "cfa|cern|ceo|center|ceb|cbs|cbre|cbn|cba|catholic|catering|cat|casino|cash|caseih|case|casa|cartier|"
                + "cars|careers|career|care|cards|caravan|car|capitalone|capital|capetown|canon|cancerresearch|camp|"
                + "camera|cam|calvinklein|call|cal|cafe|cab|bzh|buzz|buy|business|builders|build|bugatti|budapest|"
                + "brussels|brother|broker|broadway|bridgestone|bradesco|box|boutique|bot|boston|bostik|bosch|boots|"
                + "booking|book|boo|bond|bom|bofa|boehringer|boats|bnpparibas|bnl|bmw|bms|blue|bloomberg|blog|"
                + "blockbuster|blanco|blackfriday|black|biz|bio|bingo|bing|bike|bid|bible|bharti|bet|bestbuy|best|"
                + "berlin|bentley|beer|beauty|beats|bcn|bcg|bbva|bbt|bbc|bayern|bauhaus|basketball|baseball|bargains|"
                + "barefoot|barclays|barclaycard|barcelona|bar|bank|band|bananarepublic|banamex|baidu|baby|azure|axa|"
                + "aws|avianca|autos|auto|author|auspost|audio|audible|audi|auction|attorney|athleta|associates|asia|"
                + "asda|arte|art|arpa|army|archi|aramco|arab|aquarelle|apple|app|apartments|aol|anz|anquan|android|"
                + "analytics|amsterdam|amica|amfam|amex|americanfamily|americanexpress|alstom|alsace|ally|allstate|"
                + "allfinanz|alipay|alibaba|alfaromeo|akdn|airtel|airforce|airbus|aigo|aig|agency|agakhan|africa|afl|"
                + "afamilycompany|aetna|aero|aeg|adult|ads|adac|actor|active|aco|accountants|accountant|accenture|"
                + "academy|abudhabi|abogado|able|abc|abbvie|abbott|abb|abarth|aarp|aaa|onion"
                + ")(?=[^a-z0-9@+-]|$))"

        static let TWUValidCCTLD = "(?:(?:"
                + "한국|香港|澳門|新加坡|台灣|台湾|中國|中国|გე|ລາວ|ไทย|ලංකා|ഭാരതം|ಭಾರತ|భారత్|சிங்கப்பூர்|இலங்கை|இந்தியா|ଭାରତ|ભારત|ਭਾਰਤ|"
                + "ভাৰত|ভারত|বাংলা|भारोत|भारतम्|भारत|ڀارت|پاکستان|موريتانيا|مليسيا|مصر|قطر|فلسطين|عمان|عراق|سورية|سودان|"
                + "تونس|بھارت|بارت|ایران|امارات|المغرب|السعودية|الجزائر|البحرين|الاردن|հայ|қаз|укр|срб|рф|мон|мкд|ею|"
                + "бел|бг|ευ|ελ|zw|zm|za|yt|ye|ws|wf|vu|vn|vi|vg|ve|vc|va|uz|uy|us|um|uk|ug|ua|tz|tw|tv|tt|tr|tp|to|tn|"
                + "tm|tl|tk|tj|th|tg|tf|td|tc|sz|sy|sx|sv|su|st|ss|sr|so|sn|sm|sl|sk|sj|si|sh|sg|se|sd|sc|sb|sa|rw|ru|"
                + "rs|ro|re|qa|py|pw|pt|ps|pr|pn|pm|pl|pk|ph|pg|pf|pe|pa|om|nz|nu|nr|np|no|nl|ni|ng|nf|ne|nc|na|mz|my|"
                + "mx|mw|mv|mu|mt|ms|mr|mq|mp|mo|mn|mm|ml|mk|mh|mg|mf|me|md|mc|ma|ly|lv|lu|lt|ls|lr|lk|li|lc|lb|la|kz|"
                + "ky|kw|kr|kp|kn|km|ki|kh|kg|ke|jp|jo|jm|je|it|is|ir|iq|io|in|im|il|ie|id|hu|ht|hr|hn|hm|hk|gy|gw|gu|"
                + "gt|gs|gr|gq|gp|gn|gm|gl|gi|gh|gg|gf|ge|gd|gb|ga|fr|fo|fm|fk|fj|fi|eu|et|es|er|eh|eg|ee|ec|dz|do|dm|"
                + "dk|dj|de|cz|cy|cx|cw|cv|cu|cr|co|cn|cm|cl|ck|ci|ch|cg|cf|cd|cc|ca|bz|by|bw|bv|bt|bs|br|bq|bo|bn|bm|"
                + "bl|bj|bi|bh|bg|bf|be|bd|bb|ba|az|ax|aw|au|at|as|ar|aq|ao|an|am|al|ai|ag|af|ae|ad|ac"
                + ")(?=[^a-z0-9@+-]|$))"

        static let TWUValidTCOURL = "^https?://t\\.co/([a-z0-9]+)"

        static let TWUValidURLPath = "(?:(?:\(TWUValidGeneralURLPathChars)*"
                + "(?:\(TWUValidURLBalancedParens)\(TWUValidGeneralURLPathChars)*)*\(TWUValidURLPathEndingChars)"
                + ")|(?:\(TWUValidGeneralURLPathChars)+/))"

        static let emojiPattern = "(?:\u{0001f468}\u{0001f3fb}\u{200d}\u{0001f91d}\u{200d}\u{0001f468}[\u{0001f3fc}-\u{0001f3ff}]|\u{0001f468}\u{0001f3fc}\u{200d}\u{0001f91d}\u{200d}\u{0001f468}[\u{0001f3fb}\u{0001f3fd}-\u{0001f3ff}]|\u{0001f468}\u{0001f3fd}\u{200d}\u{0001f91d}\u{200d}\u{0001f468}[\u{0001f3fb}\u{0001f3fc}\u{0001f3fe}\u{0001f3ff}]|\u{0001f468}\u{0001f3fe}\u{200d}\u{0001f91d}\u{200d}\u{0001f468}[\u{0001f3fb}-\u{0001f3fd}\u{0001f3ff}]|\u{0001f468}\u{0001f3ff}\u{200d}\u{0001f91d}\u{200d}\u{0001f468}[\u{0001f3fb}-\u{0001f3fe}]|\u{0001f469}\u{0001f3fb}\u{200d}\u{0001f91d}\u{200d}\u{0001f468}[\u{0001f3fc}-\u{0001f3ff}]|\u{0001f469}\u{0001f3fb}\u{200d}\u{0001f91d}\u{200d}\u{0001f469}[\u{0001f3fc}-\u{0001f3ff}]|\u{0001f469}\u{0001f3fc}\u{200d}\u{0001f91d}\u{200d}\u{0001f468}[\u{0001f3fb}\u{0001f3fd}-\u{0001f3ff}]|\u{0001f469}\u{0001f3fc}\u{200d}\u{0001f91d}\u{200d}\u{0001f469}[\u{0001f3fb}\u{0001f3fd}-\u{0001f3ff}]|\u{0001f469}\u{0001f3fd}\u{200d}\u{0001f91d}\u{200d}\u{0001f468}[\u{0001f3fb}\u{0001f3fc}\u{0001f3fe}\u{0001f3ff}]|\u{0001f469}\u{0001f3fd}\u{200d}\u{0001f91d}\u{200d}\u{0001f469}[\u{0001f3fb}\u{0001f3fc}\u{0001f3fe}\u{0001f3ff}]|\u{0001f469}\u{0001f3fe}\u{200d}\u{0001f91d}\u{200d}\u{0001f468}[\u{0001f3fb}-\u{0001f3fd}\u{0001f3ff}]|\u{0001f469}\u{0001f3fe}\u{200d}\u{0001f91d}\u{200d}\u{0001f469}[\u{0001f3fb}-\u{0001f3fd}\u{0001f3ff}]|\u{0001f469}\u{0001f3ff}\u{200d}\u{0001f91d}\u{200d}\u{0001f468}[\u{0001f3fb}-\u{0001f3fe}]|\u{0001f469}\u{0001f3ff}\u{200d}\u{0001f91d}\u{200d}\u{0001f469}[\u{0001f3fb}-\u{0001f3fe}]|\u{0001f9d1}\u{0001f3fb}\u{200d}\u{0001f91d}\u{200d}\u{0001f9d1}[\u{0001f3fb}-\u{0001f3ff}]|\u{0001f9d1}\u{0001f3fc}\u{200d}\u{0001f91d}\u{200d}\u{0001f9d1}[\u{0001f3fb}-\u{0001f3ff}]|\u{0001f9d1}\u{0001f3fd}\u{200d}\u{0001f91d}\u{200d}\u{0001f9d1}[\u{0001f3fb}-\u{0001f3ff}]|\u{0001f9d1}\u{0001f3fe}\u{200d}\u{0001f91d}\u{200d}\u{0001f9d1}[\u{0001f3fb}-\u{0001f3ff}]|\u{0001f9d1}\u{0001f3ff}\u{200d}\u{0001f91d}\u{200d}\u{0001f9d1}[\u{0001f3fb}-\u{0001f3ff}]|\u{0001f9d1}\u{200d}\u{0001f91d}\u{200d}\u{0001f9d1}|\u{0001f46b}[\u{0001f3fb}-\u{0001f3ff}]|\u{0001f46c}[\u{0001f3fb}-\u{0001f3ff}]|\u{0001f46d}[\u{0001f3fb}-\u{0001f3ff}]|[\u{0001f46b}-\u{0001f46d}])|[\u{0001f468}\u{0001f469}\u{0001f9d1}][\u{0001f3fb}-\u{0001f3ff}]?\u{200d}(?:\u{2695}\u{fe0f}|\u{2696}\u{fe0f}|\u{2708}\u{fe0f}|[\u{0001f33e}\u{0001f373}\u{0001f393}\u{0001f3a4}\u{0001f3a8}\u{0001f3eb}\u{0001f3ed}\u{0001f4bb}\u{0001f4bc}\u{0001f527}\u{0001f52c}\u{0001f680}\u{0001f692}\u{0001f9af}-\u{0001f9b3}\u{0001f9bc}\u{0001f9bd}])|[\u{26f9}\u{0001f3cb}\u{0001f3cc}\u{0001f574}\u{0001f575}]([\u{fe0f}\u{0001f3fb}-\u{0001f3ff}]\u{200d}[\u{2640}\u{2642}]\u{fe0f})|[\u{0001f3c3}\u{0001f3c4}\u{0001f3ca}\u{0001f46e}\u{0001f471}\u{0001f473}\u{0001f477}\u{0001f481}\u{0001f482}\u{0001f486}\u{0001f487}\u{0001f645}-\u{0001f647}\u{0001f64b}\u{0001f64d}\u{0001f64e}\u{0001f6a3}\u{0001f6b4}-\u{0001f6b6}\u{0001f926}\u{0001f935}\u{0001f937}-\u{0001f939}\u{0001f93d}\u{0001f93e}\u{0001f9b8}\u{0001f9b9}\u{0001f9cd}-\u{0001f9cf}\u{0001f9d6}-\u{0001f9dd}][\u{0001f3fb}-\u{0001f3ff}]?\u{200d}[\u{2640}\u{2642}]\u{fe0f}|(?:\u{0001f468}\u{200d}\u{2764}\u{fe0f}\u{200d}\u{0001f48b}\u{200d}\u{0001f468}|\u{0001f469}\u{200d}\u{2764}\u{fe0f}\u{200d}\u{0001f48b}\u{200d}[\u{0001f468}\u{0001f469}]|\u{0001f468}\u{200d}\u{0001f468}\u{200d}\u{0001f466}\u{200d}\u{0001f466}|\u{0001f468}\u{200d}\u{0001f468}\u{200d}\u{0001f467}\u{200d}[\u{0001f466}\u{0001f467}]|\u{0001f468}\u{200d}\u{0001f469}\u{200d}\u{0001f466}\u{200d}\u{0001f466}|\u{0001f468}\u{200d}\u{0001f469}\u{200d}\u{0001f467}\u{200d}[\u{0001f466}\u{0001f467}]|\u{0001f469}\u{200d}\u{0001f469}\u{200d}\u{0001f466}\u{200d}\u{0001f466}|\u{0001f469}\u{200d}\u{0001f469}\u{200d}\u{0001f467}\u{200d}[\u{0001f466}\u{0001f467}]|\u{0001f468}\u{200d}\u{2764}\u{fe0f}\u{200d}\u{0001f468}|\u{0001f469}\u{200d}\u{2764}\u{fe0f}\u{200d}[\u{0001f468}\u{0001f469}]|\u{0001f3f3}\u{fe0f}\u{200d}\u{26a7}\u{fe0f}|\u{0001f468}\u{200d}\u{0001f466}\u{200d}\u{0001f466}|\u{0001f468}\u{200d}\u{0001f467}\u{200d}[\u{0001f466}\u{0001f467}]|\u{0001f468}\u{200d}\u{0001f468}\u{200d}[\u{0001f466}\u{0001f467}]|\u{0001f468}\u{200d}\u{0001f469}\u{200d}[\u{0001f466}\u{0001f467}]|\u{0001f469}\u{200d}\u{0001f466}\u{200d}\u{0001f466}|\u{0001f469}\u{200d}\u{0001f467}\u{200d}[\u{0001f466}\u{0001f467}]|\u{0001f469}\u{200d}\u{0001f469}\u{200d}[\u{0001f466}\u{0001f467}]|\u{0001f3f3}\u{fe0f}\u{200d}\u{0001f308}|\u{0001f3f4}\u{200d}\u{2620}\u{fe0f}|\u{0001f46f}\u{200d}\u{2640}\u{fe0f}|\u{0001f46f}\u{200d}\u{2642}\u{fe0f}|\u{0001f93c}\u{200d}\u{2640}\u{fe0f}|\u{0001f93c}\u{200d}\u{2642}\u{fe0f}|\u{0001f9de}\u{200d}\u{2640}\u{fe0f}|\u{0001f9de}\u{200d}\u{2642}\u{fe0f}|\u{0001f9df}\u{200d}\u{2640}\u{fe0f}|\u{0001f9df}\u{200d}\u{2642}\u{fe0f}|\u{0001f415}\u{200d}\u{0001f9ba}|\u{0001f441}\u{200d}\u{0001f5e8}|\u{0001f468}\u{200d}[\u{0001f466}\u{0001f467}]|\u{0001f469}\u{200d}[\u{0001f466}\u{0001f467}])|[#*0-9]\u{fe0f}?\u{20e3}|(?:[©®\u{2122}\u{265f}]\u{fe0f})|[\u{203c}\u{2049}\u{2139}\u{2194}-\u{2199}\u{21a9}\u{21aa}\u{231a}\u{231b}\u{2328}\u{23cf}\u{23ed}-\u{23ef}\u{23f1}\u{23f2}\u{23f8}-\u{23fa}\u{24c2}\u{25aa}\u{25ab}\u{25b6}\u{25c0}\u{25fb}-\u{25fe}\u{2600}-\u{2604}\u{260e}\u{2611}\u{2614}\u{2615}\u{2618}\u{2620}\u{2622}\u{2623}\u{2626}\u{262a}\u{262e}\u{262f}\u{2638}-\u{263a}\u{2640}\u{2642}\u{2648}-\u{2653}\u{2660}\u{2663}\u{2665}\u{2666}\u{2668}\u{267b}\u{267f}\u{2692}-\u{2697}\u{2699}\u{269b}\u{269c}\u{26a0}\u{26a1}\u{26a7}\u{26aa}\u{26ab}\u{26b0}\u{26b1}\u{26bd}\u{26be}\u{26c4}\u{26c5}\u{26c8}\u{26cf}\u{26d1}\u{26d3}\u{26d4}\u{26e9}\u{26ea}\u{26f0}-\u{26f5}\u{26f8}\u{26fa}\u{26fd}\u{2702}\u{2708}\u{2709}\u{270f}\u{2712}\u{2714}\u{2716}\u{271d}\u{2721}\u{2733}\u{2734}\u{2744}\u{2747}\u{2757}\u{2763}\u{2764}\u{27a1}\u{2934}\u{2935}\u{2b05}-\u{2b07}\u{2b1b}\u{2b1c}\u{2b50}\u{2b55}\u{3030}\u{303d}\u{3297}\u{3299}\u{0001f004}\u{0001f170}\u{0001f171}\u{0001f17e}\u{0001f17f}\u{0001f202}\u{0001f21a}\u{0001f22f}\u{0001f237}\u{0001f321}\u{0001f324}-\u{0001f32c}\u{0001f336}\u{0001f37d}\u{0001f396}\u{0001f397}\u{0001f399}-\u{0001f39b}\u{0001f39e}\u{0001f39f}\u{0001f3cd}\u{0001f3ce}\u{0001f3d4}-\u{0001f3df}\u{0001f3f3}\u{0001f3f5}\u{0001f3f7}\u{0001f43f}\u{0001f441}\u{0001f4fd}\u{0001f549}\u{0001f54a}\u{0001f56f}\u{0001f570}\u{0001f573}\u{0001f576}-\u{0001f579}\u{0001f587}\u{0001f58a}-\u{0001f58d}\u{0001f5a5}\u{0001f5a8}\u{0001f5b1}\u{0001f5b2}\u{0001f5bc}\u{0001f5c2}-\u{0001f5c4}\u{0001f5d1}-\u{0001f5d3}\u{0001f5dc}-\u{0001f5de}\u{0001f5e1}\u{0001f5e3}\u{0001f5e8}\u{0001f5ef}\u{0001f5f3}\u{0001f5fa}\u{0001f6cb}\u{0001f6cd}-\u{0001f6cf}\u{0001f6e0}-\u{0001f6e5}\u{0001f6e9}\u{0001f6f0}\u{0001f6f3}](?:\u{fe0f}|(?!\u{fe0e}))|(?:[\u{261d}\u{26f7}\u{26f9}\u{270c}\u{270d}\u{0001f3cb}\u{0001f3cc}\u{0001f574}\u{0001f575}\u{0001f590}](?:\u{fe0f}|(?!\u{fe0e}))|[\u{270a}\u{270b}\u{0001f385}\u{0001f3c2}-\u{0001f3c4}\u{0001f3c7}\u{0001f3ca}\u{0001f442}\u{0001f443}\u{0001f446}-\u{0001f450}\u{0001f466}-\u{0001f469}\u{0001f46e}\u{0001f470}-\u{0001f478}\u{0001f47c}\u{0001f481}-\u{0001f483}\u{0001f485}-\u{0001f487}\u{0001f4aa}\u{0001f57a}\u{0001f595}\u{0001f596}\u{0001f645}-\u{0001f647}\u{0001f64b}-\u{0001f64f}\u{0001f6a3}\u{0001f6b4}-\u{0001f6b6}\u{0001f6c0}\u{0001f6cc}\u{0001f90f}\u{0001f918}-\u{0001f91c}\u{0001f91e}\u{0001f91f}\u{0001f926}\u{0001f930}-\u{0001f939}\u{0001f93d}\u{0001f93e}\u{0001f9b5}\u{0001f9b6}\u{0001f9b8}\u{0001f9b9}\u{0001f9bb}\u{0001f9cd}-\u{0001f9cf}\u{0001f9d1}-\u{0001f9dd}])[\u{0001f3fb}-\u{0001f3ff}]?|(?:\u{0001f3f4}\u{000e0067}\u{000e0062}\u{000e0065}\u{000e006e}\u{000e0067}\u{000e007f}|\u{0001f3f4}\u{000e0067}\u{000e0062}\u{000e0073}\u{000e0063}\u{000e0074}\u{000e007f}|\u{0001f3f4}\u{000e0067}\u{000e0062}\u{000e0077}\u{000e006c}\u{000e0073}\u{000e007f}|\u{0001f1e6}[\u{0001f1e8}-\u{0001f1ec}\u{0001f1ee}\u{0001f1f1}\u{0001f1f2}\u{0001f1f4}\u{0001f1f6}-\u{0001f1fa}\u{0001f1fc}\u{0001f1fd}\u{0001f1ff}]|\u{0001f1e7}[\u{0001f1e6}\u{0001f1e7}\u{0001f1e9}-\u{0001f1ef}\u{0001f1f1}-\u{0001f1f4}\u{0001f1f6}-\u{0001f1f9}\u{0001f1fb}\u{0001f1fc}\u{0001f1fe}\u{0001f1ff}]|\u{0001f1e8}[\u{0001f1e6}\u{0001f1e8}\u{0001f1e9}\u{0001f1eb}-\u{0001f1ee}\u{0001f1f0}-\u{0001f1f5}\u{0001f1f7}\u{0001f1fa}-\u{0001f1ff}]|\u{0001f1e9}[\u{0001f1ea}\u{0001f1ec}\u{0001f1ef}\u{0001f1f0}\u{0001f1f2}\u{0001f1f4}\u{0001f1ff}]|\u{0001f1ea}[\u{0001f1e6}\u{0001f1e8}\u{0001f1ea}\u{0001f1ec}\u{0001f1ed}\u{0001f1f7}-\u{0001f1fa}]|\u{0001f1eb}[\u{0001f1ee}-\u{0001f1f0}\u{0001f1f2}\u{0001f1f4}\u{0001f1f7}]|\u{0001f1ec}[\u{0001f1e6}\u{0001f1e7}\u{0001f1e9}-\u{0001f1ee}\u{0001f1f1}-\u{0001f1f3}\u{0001f1f5}-\u{0001f1fa}\u{0001f1fc}\u{0001f1fe}]|\u{0001f1ed}[\u{0001f1f0}\u{0001f1f2}\u{0001f1f3}\u{0001f1f7}\u{0001f1f9}\u{0001f1fa}]|\u{0001f1ee}[\u{0001f1e8}-\u{0001f1ea}\u{0001f1f1}-\u{0001f1f4}\u{0001f1f6}-\u{0001f1f9}]|\u{0001f1ef}[\u{0001f1ea}\u{0001f1f2}\u{0001f1f4}\u{0001f1f5}]|\u{0001f1f0}[\u{0001f1ea}\u{0001f1ec}-\u{0001f1ee}\u{0001f1f2}\u{0001f1f3}\u{0001f1f5}\u{0001f1f7}\u{0001f1fc}\u{0001f1fe}\u{0001f1ff}]|\u{0001f1f1}[\u{0001f1e6}-\u{0001f1e8}\u{0001f1ee}\u{0001f1f0}\u{0001f1f7}-\u{0001f1fb}\u{0001f1fe}]|\u{0001f1f2}[\u{0001f1e6}\u{0001f1e8}-\u{0001f1ed}\u{0001f1f0}-\u{0001f1ff}]|\u{0001f1f3}[\u{0001f1e6}\u{0001f1e8}\u{0001f1ea}-\u{0001f1ec}\u{0001f1ee}\u{0001f1f1}\u{0001f1f4}\u{0001f1f5}\u{0001f1f7}\u{0001f1fa}\u{0001f1ff}]|\u{0001f1f4}\u{0001f1f2}|\u{0001f1f5}[\u{0001f1e6}\u{0001f1ea}-\u{0001f1ed}\u{0001f1f0}-\u{0001f1f3}\u{0001f1f7}-\u{0001f1f9}\u{0001f1fc}\u{0001f1fe}]|\u{0001f1f6}\u{0001f1e6}|\u{0001f1f7}[\u{0001f1ea}\u{0001f1f4}\u{0001f1f8}\u{0001f1fa}\u{0001f1fc}]|\u{0001f1f8}[\u{0001f1e6}-\u{0001f1ea}\u{0001f1ec}-\u{0001f1f4}\u{0001f1f7}-\u{0001f1f9}\u{0001f1fb}\u{0001f1fd}-\u{0001f1ff}]|\u{0001f1f9}[\u{0001f1e6}\u{0001f1e8}\u{0001f1e9}\u{0001f1eb}-\u{0001f1ed}\u{0001f1ef}-\u{0001f1f4}\u{0001f1f7}\u{0001f1f9}\u{0001f1fb}\u{0001f1fc}\u{0001f1ff}]|\u{0001f1fa}[\u{0001f1e6}\u{0001f1ec}\u{0001f1f2}\u{0001f1f3}\u{0001f1f8}\u{0001f1fe}\u{0001f1ff}]|\u{0001f1fb}[\u{0001f1e6}\u{0001f1e8}\u{0001f1ea}\u{0001f1ec}\u{0001f1ee}\u{0001f1f3}\u{0001f1fa}]|\u{0001f1fc}[\u{0001f1eb}\u{0001f1f8}]|\u{0001f1fd}\u{0001f1f0}|\u{0001f1fe}[\u{0001f1ea}\u{0001f1f9}]|\u{0001f1ff}[\u{0001f1e6}\u{0001f1f2}\u{0001f1fc}]|[\u{23e9}-\u{23ec}\u{23f0}\u{23f3}\u{267e}\u{26ce}\u{2705}\u{2728}\u{274c}\u{274e}\u{2753}-\u{2755}\u{2795}-\u{2797}\u{27b0}\u{27bf}\u{e50a}\u{0001f0cf}\u{0001f18e}\u{0001f191}-\u{0001f19a}\u{0001f1e6}-\u{0001f1ff}\u{0001f201}\u{0001f232}-\u{0001f236}\u{0001f238}-\u{0001f23a}\u{0001f250}\u{0001f251}\u{0001f300}-\u{0001f320}\u{0001f32d}-\u{0001f335}\u{0001f337}-\u{0001f37c}\u{0001f37e}-\u{0001f384}\u{0001f386}-\u{0001f393}\u{0001f3a0}-\u{0001f3c1}\u{0001f3c5}\u{0001f3c6}\u{0001f3c8}\u{0001f3c9}\u{0001f3cf}-\u{0001f3d3}\u{0001f3e0}-\u{0001f3f0}\u{0001f3f4}\u{0001f3f8}-\u{0001f43e}\u{0001f440}\u{0001f444}\u{0001f445}\u{0001f451}-\u{0001f465}\u{0001f46a}\u{0001f46f}\u{0001f479}-\u{0001f47b}\u{0001f47d}-\u{0001f480}\u{0001f484}\u{0001f488}-\u{0001f4a9}\u{0001f4ab}-\u{0001f4fc}\u{0001f4ff}-\u{0001f53d}\u{0001f54b}-\u{0001f54e}\u{0001f550}-\u{0001f567}\u{0001f5a4}\u{0001f5fb}-\u{0001f644}\u{0001f648}-\u{0001f64a}\u{0001f680}-\u{0001f6a2}\u{0001f6a4}-\u{0001f6b3}\u{0001f6b7}-\u{0001f6bf}\u{0001f6c1}-\u{0001f6c5}\u{0001f6d0}-\u{0001f6d2}\u{0001f6d5}\u{0001f6eb}\u{0001f6ec}\u{0001f6f4}-\u{0001f6fa}\u{0001f7e0}-\u{0001f7eb}\u{0001f90d}\u{0001f90e}\u{0001f910}-\u{0001f917}\u{0001f91d}\u{0001f920}-\u{0001f925}\u{0001f927}-\u{0001f92f}\u{0001f93a}\u{0001f93c}\u{0001f93f}-\u{0001f945}\u{0001f947}-\u{0001f971}\u{0001f973}-\u{0001f976}\u{0001f97a}-\u{0001f9a2}\u{0001f9a5}-\u{0001f9aa}\u{0001f9ae}-\u{0001f9b4}\u{0001f9b7}\u{0001f9ba}\u{0001f9bc}-\u{0001f9ca}\u{0001f9d0}\u{0001f9de}-\u{0001f9ff}\u{0001fa70}-\u{0001fa73}\u{0001fa78}-\u{0001fa7a}\u{0001fa80}-\u{0001fa82}\u{0001fa90}-\u{0001fa95}])|\u{fe0f}"
    }

}

extension String {
    var isEmoji: Bool {
        do {
            let range = NSMakeRange(0, utf16.count)
            let regex = try NSRegularExpression(pattern: TwitterText.Regexp.emojiPattern, options: [])
            let matches = regex.matches(in: self, options: [], range: range)

            return matches.count == 1
                    && matches[0].range.location != NSNotFound
                    && NSMaxRange(matches[0].range) <= self.utf16.count
        } catch {
            return false
        }
    }
}
