import Foundation
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

    func userRequest(username: String) async throws -> TwitterUser? {
        let parameters: Parameters = [
            "usernames": username,
            "user.fields": "profile_image_url"
        ]

        let headers = bearerToken.map { HTTPHeaders([HTTPHeader.authorization(bearerToken: $0)]) }

        let usersResponse: TwitterUsersResponse = try await networkManager.fetch(url: "\(baseUrl)/users/by", method: .get, parameters: parameters, headers: headers)
        return usersResponse.users.first
    }

    func tweets(user: TwitterUser, paginationToken: String? = nil, sinceId: String? = nil) async throws -> TweetsPage {
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

        let tweetsResponse: TweetsPageResponse = try await networkManager.fetch(url: "\(baseUrl)/users/\(user.id)/tweets", method: .get, parameters: parameters, headers: headers)
        return (tweets: tweetsResponse.tweets(user: user), nextToken: tweetsResponse.nextToken)
    }

}
