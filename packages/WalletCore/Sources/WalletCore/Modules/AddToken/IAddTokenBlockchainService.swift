import MarketKit

protocol IAddTokenBlockchainService {
    var placeholder: String { get }
    func validate(reference: String) throws
    func tokenQuery(reference: String) -> TokenQuery
    func token(reference: String) async throws -> Token
}
