import Foundation
import ObjectMapper

class Tweet {
    let id: String
    let user: TwitterUser
    let text: String
    let date: Date
    let entities: [Entity]
    let attachments: [Attachment]
    let referencedTweet: (referenceType: ReferenceType, tweet: Tweet)?
    
    init(id: String, user: TwitterUser, text: String, date: Date, entities: [Entity], attachments: [Attachment], referencedTweet: (referenceType: ReferenceType, tweet: Tweet)?) {
        self.id = id
        self.user = user
        self.text = text
        self.date = date
        self.entities = entities
        self.attachments = attachments
        self.referencedTweet = referencedTweet
    }

    struct Entity {
        let type: EntityType
        let start: Int
        let end: Int
    }

    enum EntityType {
        case mention(username: String)
        case url(url: String, displayUrl: String)
        case hashtag(tag: String)
    }

    enum Attachment {
        case photo(url: String)
        case video(previewImageUrl: String)
        case poll(options: [(position: Int, label: String, votes: Int)])
    }

    enum ReferenceType {
        case quoted, retweeted, repliedTo
    }

}
