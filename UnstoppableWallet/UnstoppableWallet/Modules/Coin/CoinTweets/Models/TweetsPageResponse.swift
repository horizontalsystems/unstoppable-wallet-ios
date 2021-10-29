import Foundation
import ObjectMapper

class TweetsPageResponse: ImmutableMappable {
    let data: [RawTweet]
    let media: [Media]
    let polls: [Poll]
    let users: [TwitterUser]
    let referencedTweets: [RawTweet]
    let nextToken: String?

    required init(map: Map) throws {
        data = try map.value("data")
        media = (try? map.value("includes.media")) ?? []
        polls = (try? map.value("includes.polls")) ?? []
        users = (try? map.value("includes.users")) ?? []
        referencedTweets = (try? map.value("includes.tweets")) ?? []
        nextToken = try? map.value("meta.next_token")
    }

    func tweets(user: TwitterUser) -> [Tweet] {
        data.map { rawTweet in
            var attachments = [Tweet.Attachment]()
            for mediaKey in rawTweet.mediaKeys {
                if let media = media.first(where: { singleMedia in singleMedia.key == mediaKey }) {
                    if media.type == "photo", let url = media.url {
                        attachments.append(.photo(url: url))
                    } else if media.type == "video", let previewImageUrl = media.previewImageUrl {
                        attachments.append(.video(previewImageUrl: previewImageUrl))
                    }
                }
            }
            for pollId in rawTweet.pollIds {
                if let poll = polls.first(where: { $0.id == pollId }) {
                    let options = poll.options.map { (position: $0.position, label: $0.label, votes: $0.votes) }
                    attachments.append(.poll(options: options))
                }
            }

            var referencedTweet: (referenceType: Tweet.ReferenceType, tweet: Tweet)? = nil
            if let tweetReference = rawTweet.referencedTweets.first,
               let rawReferencedTweet = referencedTweets.first(where: { tweet in tweet.id == tweetReference.id }),
               let referencedTweetAuthor = users.first(where: { user in user.id == rawReferencedTweet.authorId }) {
                let tweet = Tweet(
                        id: rawReferencedTweet.id,
                        user: referencedTweetAuthor,
                        text: rawReferencedTweet.text,
                        date: rawReferencedTweet.date,
                        attachments: [],
                        referencedTweet: nil
                )

                switch tweetReference.type {
                case "quoted": referencedTweet = (referenceType: .quoted, tweet: tweet)
                case "retweeted": referencedTweet = (referenceType: .retweeted, tweet: tweet)
                case "replied_to": referencedTweet = (referenceType: .replied, tweet: tweet)
                default: ()
                }
            }

            return Tweet(
                    id: rawTweet.id,
                    user: user,
                    text: rawTweet.text,
                    date: rawTweet.date,
                    attachments: attachments,
                    referencedTweet: referencedTweet
            )
        }
    }

}

extension TweetsPageResponse {

    struct RawTweet: ImmutableMappable {
        let id: String
        let date: Date
        let authorId: String
        let text: String
        let mediaKeys: [String]
        let pollIds: [String]
        let referencedTweets: [ReferencedTweet]

        init(map: Map) throws {
            id = try map.value("id")
            date = try map.value("created_at", using: TweetsPageResponse.utcDateTransform)
            authorId = try map.value("author_id")
            text = try map.value("text")
            mediaKeys = (try? map.value("attachments.media_keys")) ?? []
            pollIds = (try? map.value("attachments.poll_ids")) ?? []
            referencedTweets = (try? map.value("referenced_tweets")) ?? []
        }
    }

    struct RawEntities: ImmutableMappable {
        let urls: [URL]
        let mentions: [Mention]
        let hashTags: [Hashtag]

        init(urls: [URL], mentions: [Mention], hashTags: [Hashtag]) {
            self.urls = urls
            self.mentions = mentions
            self.hashTags = hashTags
        }
        
        init(map: Map) throws {
            urls = (try? map.value("urls")) ?? []
            mentions = (try? map.value("mentions")) ?? []
            hashTags = (try? map.value("hashtags")) ?? []
        }
    }

    struct URL: ImmutableMappable {
        let start: Int
        let end: Int
        let url: String
        let displayUrl: String

        init(map: Map) throws {
            start = try map.value("start")
            end = try map.value("end")
            url = try map.value("url")
            displayUrl = try map.value("display_url")
        }
    }

    struct Mention: ImmutableMappable {
        let start: Int
        let end: Int
        let username: String

        init(map: Map) throws {
            start = try map.value("start")
            end = try map.value("end")
            username = try map.value("username")
        }
    }

    struct Hashtag: ImmutableMappable {
        let start: Int
        let end: Int
        let tag: String

        init(map: Map) throws {
            start = try map.value("start")
            end = try map.value("end")
            tag = try map.value("tag")
        }
    }

    struct Media: ImmutableMappable {
        let key: String
        let type: String
        let url: String?
        let previewImageUrl: String?

        init(map: Map) throws {
            key = try map.value("media_key")
            type = try map.value("type")
            url = try map.value("url")
            previewImageUrl = try map.value("preview_image_url")
        }
    }

    struct Poll: ImmutableMappable {
        let id: String
        let options: [PollOption]

        init(map: Map) throws {
            id = try map.value("id")
            options = try map.value("options")
        }
    }

    struct PollOption: ImmutableMappable {
        let position: Int
        let label: String
        let votes: Int

        init(map: Map) throws {
            position = try map.value("position")
            label = try map.value("label")
            votes = try map.value("votes")
        }
    }

    struct ReferencedTweet: ImmutableMappable {
        let type: String
        let id: String

        init(map: Map) throws {
            type = try map.value("type")
            id = try map.value("id")
        }
    }

}

extension TweetsPageResponse {

    static var utcDateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")!
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter
    }

    static let utcDateTransform: TransformOf<Date, String> = TransformOf(fromJSON: { string -> Date? in
        guard let string = string else { return nil }
        return utcDateFormatter.date(from: string)
    }, toJSON: { (value: Date?) in
        guard let value = value else { return nil }
        return utcDateFormatter.string(from: value)
    })

}
