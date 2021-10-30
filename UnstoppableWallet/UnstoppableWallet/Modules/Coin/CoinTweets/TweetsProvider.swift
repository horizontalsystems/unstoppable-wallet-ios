import Foundation
import RxSwift
import HsToolKit
import ObjectMapper
import Alamofire

class TweetsProvider {
    typealias TweetsPage = (tweets: [Tweet], nextToken: String?)

    private let baseUrl = "https://api.twitter.com/2"
    private let networkManager: NetworkManager
    private let bearerToken: String?

    init(networkManager: NetworkManager, bearerToken: String?) {
        self.networkManager = networkManager
        self.bearerToken = bearerToken
    }

    func userRequestSingle(username: String) -> Single<TwitterUser?> {
        let parameters: Parameters = [
            "usernames": username,
            "user.fields": "profile_image_url"
        ]

        let headers = bearerToken.map { HTTPHeaders([HTTPHeader.authorization(bearerToken: $0)]) }

        return networkManager
                .single(url: "\(baseUrl)/users/by", method: .get, parameters: parameters, headers: headers)
                .map { (usersResponse: TwitterUsersResponse) -> TwitterUser? in
                    usersResponse.users.first
                }
    }

    func tweetsSingle(user: TwitterUser, paginationToken: String? = nil, sinceId: String? = nil) -> Single<TweetsPage> {
        var parameters: Parameters = [
            "max_results": 50,
            "expansions": "attachments.poll_ids,attachments.media_keys,referenced_tweets.id,referenced_tweets.id.author_id",
            "media.fields": "media_key,preview_image_url,type,url",
            "tweet.fields": "id,author_id,created_at,attachments",
            "user.fields": "profile_image_url"
        ]

        if let token = paginationToken {
           parameters["next_token"] = token
        }

        if let sinceId = sinceId {
            parameters["since_id"] = sinceId
        }

        let headers = bearerToken.map { HTTPHeaders([HTTPHeader.authorization(bearerToken: $0)]) }

        return networkManager
                .single(url: "\(baseUrl)/users/\(user.id)/tweets", method: .get, parameters: parameters, headers: headers)
                .map { (tweetsResponse: TweetsPageResponse) -> TweetsPage in
                    (tweets: tweetsResponse.tweets(user: user), nextToken: tweetsResponse.nextToken)
                }
    }

}
