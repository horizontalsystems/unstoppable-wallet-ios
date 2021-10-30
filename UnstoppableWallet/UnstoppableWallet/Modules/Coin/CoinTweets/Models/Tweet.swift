import Foundation
import ObjectMapper

class Tweet {
    let id: String
    let user: TwitterUser
    let text: String
    let date: Date
    let attachments: [Attachment]
    let referencedTweet: (referenceType: ReferenceType, tweet: Tweet)?
    
    init(id: String, user: TwitterUser, text: String, date: Date, attachments: [Attachment], referencedTweet: (referenceType: ReferenceType, tweet: Tweet)?) {
        self.id = id
        self.user = user
        self.text = text
        self.date = date
        self.attachments = attachments
        self.referencedTweet = referencedTweet
    }

    enum Attachment {
        case photo(url: String)
        case video(previewImageUrl: String)
        case poll(options: [(position: Int, label: String, votes: Int)])
    }

    enum ReferenceType: String {
        case quoted, retweeted, replied
    }

}
