import Foundation
import HsToolKit

extension Thorchain {
    
    /// GET Data from Midgard API. This function is generic and works for all structs conforming to MidgardAPIResponse protocol.
    /// - Parameters:
    ///   - completionHandler: Called on main thread. Will contain an array of MidgardAPIResponseObject's, or nil for any errors.
    ///   - midgardAPIURL: (optional) a URL for Midgard. If none specified, uses thorchain.info
    ///   - endpoint: Midgard API Endpoint, e.g. `/pools`.
    ///   - queryItems: Array of query items to append. If unspecified, defaults to empty array.
    func getMidgardResponse<MidgardType>(_ completionHandler: @escaping (MidgardType?) -> (), midgardAPIURL: URL? = nil, endpoint: String, queryItems: [URLQueryItem] = []) where MidgardType: MidgardAPIResponse {
        let midgardURL : URL
        if let midgardAPIURL = midgardAPIURL {
            midgardURL = midgardAPIURL //user provided
        } else {
            midgardURL = chain.midgardURL
        }
        
        // Construct URL
        guard var urlComponents = URLComponents(string: midgardURL.absoluteString) else {
            debugLog("Thorchain Error: Could not generate URL components from \(midgardURL.absoluteString)")
            completionHandler(nil)
            return
        }
        urlComponents.path = endpoint
        urlComponents.queryItems = queryItems
        guard let url = urlComponents.url else {
            debugLog("Thorchain Error: Could not generate URL from \(urlComponents.description)")
            completionHandler(nil)
            return
        }
        
        let midgardApiTask = urlSession.dataTask(with: url) { (data, response, error) in
            guard let data = data, error == nil else {
                self.debugLog("Thorchain Error: Midgard API error")
                completionHandler(nil)
                return
            }
            do {
                let pools : MidgardType = try self.jsonDecoder.decode(MidgardType.self, from: data)
                completionHandler(pools) //Success
            }
            catch {
                self.debugLog("Thorchain Exception Decoding Midgard API:\n\(error)")
                completionHandler(nil)
            }
        }
        midgardApiTask.resume()
    }
}


/// Convenience accessors for various Midgard API
extension Thorchain {
    
    /// GET Health from Midgard API `/health`
    /// - Parameters:
    ///   - completionHandler: Called on main thread. Will contain a Midgard.HealthInfo struct, or nil for any errors.
    ///   - midgardAPIURL: (optional) a URL for Midgard. If none specified, uses thorchain.info
    public func getMidgardHealthInfo(_ completionHandler: @escaping (Midgard.HealthInfo?) -> (), midgardAPIURL: URL? = nil) {
        getMidgardResponse(completionHandler, midgardAPIURL: midgardAPIURL, endpoint: "/health")
    }
    
    
    /// GET all Pools from Midgard API `/pools`
    /// - Parameters:
    ///   - status: (optional) Filter for only pools with this status
    ///   - completionHandler: Called on main thread. Will contain an array of Midgard.Pool's, or nil for any errors.
    ///   - midgardAPIURL: (optional) a URL for Midgard. If none specified, uses thorchain.info
    public func getMidgardPools(midgardAPIURL: URL? = nil) async throws -> [Midgard.Pool] {
        let url = (midgardAPIURL ?? chain.midgardURL).appendingPathComponent("/thorchain/pools")
        return try await networkManager.fetchArray(url: url)

    }

    public func getMidgardPools(filterByStatus status : Midgard.PoolStatus? = nil,
                                _ completionHandler: @escaping ([Midgard.Pool]?) -> (),
                                midgardAPIURL: URL? = nil) {
        let queryItems = status != nil ? [URLQueryItem(name: "status", value: status!.rawValue)] : []
        getMidgardResponse(completionHandler, midgardAPIURL: midgardAPIURL, endpoint: "/thorchain/pools", queryItems: queryItems)
    }
    
    
    /// GET Pool Details from Midgard API `/pool/{asset}`
    /// - Parameters:
    ///   - asset: Asset type, e.g. "BNB.BNB"
    ///   - completionHandler: Called on main thread. Will contain a MidgardPool struct, or nil for any errors.
    ///   - midgardAPIURL: (optional) a URL for Midgard. If none specified, uses thorchain.info
    public func getMidgardPool(asset : String, _ completionHandler: @escaping (Midgard.Pool?) -> (), midgardAPIURL: URL? = nil) {
        getMidgardResponse(completionHandler, midgardAPIURL: midgardAPIURL, endpoint: "/pool/\(asset)")
    }
    

    /// GET Pool Statistics from Midgard API `/pool/{asset}/stats`
    /// - Parameters:
    ///   - asset: Asset type, e.g. "BNB.BNB"
    ///   - period: Restricts aggregation type fields to the last period only. Default is 30d
    ///   - completionHandler: Called on main thread. Will contain a Midgard.PoolStatistics struct, or nil for any errors.
    ///   - midgardAPIURL: (optional) a URL for Midgard. If none specified, uses thorchain.info
    public func getMidgardPoolStatistics(asset : String,
                                         period : Midgard.PoolPeriod = .thirtyDays,
                                         _ completionHandler: @escaping (Midgard.PoolStatistics?) -> (),
                                         midgardAPIURL: URL? = nil) {
        let queryItems = [URLQueryItem(name: "period", value: period.rawValue)]
        getMidgardResponse(completionHandler, midgardAPIURL: midgardAPIURL, endpoint: "/pool/\(asset)/stats", queryItems: queryItems)
    }
    

    /// GET Pool Depth/History from Midgard API `/history/depths/{pool}`
    /// - Parameters:
    ///   - pool: Pool name, e.g. "BTC.BTC"
    ///   - interval: Interval of calculations. With Interval parameter it returns a series of time buckets
    ///   - count: Number of intervals to return. Should be between [1..400].
    ///   - to: End time of the query. If only count is given, defaults to now.
    ///   - from: Start time of the query.
    ///   - completionHandler: Called on main thread. Will contain a Midgard.PriceDepthHistory struct, or nil for any errors.
    ///   - midgardAPIURL: (optional) a URL for Midgard. If none specified, uses thorchain.info
    public func getMidgardDepthPriceHistory(pool : String,
                                            interval : Midgard.HistoryInterval? = nil,
                                            count : Int? = nil,
                                            to : Date? = nil,
                                            from : Date? = nil,
                                            _ completionHandler: @escaping (Midgard.PriceDepthHistory?) -> (),
                                            midgardAPIURL: URL? = nil) {
        var queryItems = [URLQueryItem]()
        if let interval = interval {
            queryItems.append(URLQueryItem(name: "interval", value: interval.rawValue))
        }
        if let count = count {
            assert(count >= 1 && count <= 400)  // Count must be [1..400]
            queryItems.append(URLQueryItem(name: "count", value: "\(count)"))
        }
        if let to = to {
            queryItems.append(URLQueryItem(name: "to", value: "\(Int(to.timeIntervalSince1970))"))
        }
        if let from = from {
            queryItems.append(URLQueryItem(name: "from", value: "\(Int(from.timeIntervalSince1970))"))
        }
        getMidgardResponse(completionHandler, midgardAPIURL: midgardAPIURL, endpoint: "/history/depths/\(pool)", queryItems: queryItems)
    }
    
    
    /// GET Earnings History from Midgard API `/history/earnings`
    /// - Parameters:
    ///   - interval: Interval of calculations. With Interval parameter it returns a series of time buckets
    ///   - count: Number of intervals to return. Should be between [1..400].
    ///   - to: End time of the query. If only count is given, defaults to now.
    ///   - from: Start time of the query.
    ///   - completionHandler: Called on main thread. Will contain a Midgard.EarningsHistory struct, or nil for any errors.
    ///   - midgardAPIURL: (optional) a URL for Midgard. If none specified, uses thorchain.info
    public func getMidgardEarningsHistory(interval : Midgard.HistoryInterval? = nil,
                                            count : Int? = nil,
                                            to : Date? = nil,
                                            from : Date? = nil,
                                            _ completionHandler: @escaping (Midgard.EarningsHistory?) -> (),
                                            midgardAPIURL: URL? = nil) {
        var queryItems = [URLQueryItem]()
        if let interval = interval {
            queryItems.append(URLQueryItem(name: "interval", value: interval.rawValue))
        }
        if let count = count {
            assert(count >= 1 && count <= 400)  // Count must be [1..400]
            queryItems.append(URLQueryItem(name: "count", value: "\(count)"))
        }
        if let to = to {
            queryItems.append(URLQueryItem(name: "to", value: "\(Int(to.timeIntervalSince1970))"))
        }
        if let from = from {
            queryItems.append(URLQueryItem(name: "from", value: "\(Int(from.timeIntervalSince1970))"))
        }
        getMidgardResponse(completionHandler, midgardAPIURL: midgardAPIURL, endpoint: "/history/earnings", queryItems: queryItems)
    }
    
    
    /// GET Swaps History from Midgard API `/history/swaps`
    /// - Parameters:
    ///   - pool: Return history given pool. Returns sum of all pools if nil.
    ///   - interval: Interval of calculations. With Interval parameter it returns a series of time buckets
    ///   - count: Number of intervals to return. Should be between [1..400].
    ///   - to: End time of the query. If only count is given, defaults to now.
    ///   - from: Start time of the query.
    ///   - completionHandler: Called on main thread. Will contain a Midgard.EarningsHistory struct, or nil for any errors.
    ///   - midgardAPIURL: (optional) a URL for Midgard. If none specified, uses thorchain.info
    public func getMidgardSwapsHistory(pool : String?,
                                       interval : Midgard.HistoryInterval? = nil,
                                       count : Int? = nil,
                                       to : Date? = nil,
                                       from : Date? = nil,
                                       _ completionHandler: @escaping (Midgard.SwapsHistory?) -> (),
                                       midgardAPIURL: URL? = nil) {
        var queryItems = [URLQueryItem]()
        if let pool = pool {
            queryItems.append(URLQueryItem(name: "pool", value: pool))
        }
        if let interval = interval {
            queryItems.append(URLQueryItem(name: "interval", value: interval.rawValue))
        }
        if let count = count {
            assert(count >= 1 && count <= 400)  // Count must be [1..400]
            queryItems.append(URLQueryItem(name: "count", value: "\(count)"))
        }
        if let to = to {
            queryItems.append(URLQueryItem(name: "to", value: "\(Int(to.timeIntervalSince1970))"))
        }
        if let from = from {
            queryItems.append(URLQueryItem(name: "from", value: "\(Int(from.timeIntervalSince1970))"))
        }
        getMidgardResponse(completionHandler, midgardAPIURL: midgardAPIURL, endpoint: "/history/swaps", queryItems: queryItems)
    }
    
    /// GET Liquidity Changes History from Midgard API `/history/liquidity_changes`
    /// - Parameters:
    ///   - pool: Return history given pool. Returns sum of all pools if nil.
    ///   - interval: Interval of calculations. With Interval parameter it returns a series of time buckets
    ///   - count: Number of intervals to return. Should be between [1..400].
    ///   - to: End time of the query. If only count is given, defaults to now.
    ///   - from: Start time of the query.
    ///   - completionHandler: Called on main thread. Will contain a Midgard.EarningsHistory struct, or nil for any errors.
    ///   - midgardAPIURL: (optional) a URL for Midgard. If none specified, uses thorchain.info
    public func getMidgardLiquidityChangesHistory(pool : String? = nil,
                                       interval : Midgard.HistoryInterval? = nil,
                                       count : Int? = nil,
                                       to : Date? = nil,
                                       from : Date? = nil,
                                       _ completionHandler: @escaping (Midgard.LiquidityHistory?) -> (),
                                       midgardAPIURL: URL? = nil) {
        var queryItems = [URLQueryItem]()
        if let pool = pool {
            queryItems.append(URLQueryItem(name: "pool", value: pool))
        }
        if let interval = interval {
            queryItems.append(URLQueryItem(name: "interval", value: interval.rawValue))
        }
        if let count = count {
            assert(count >= 1 && count <= 400)  // Count must be [1..400]
            queryItems.append(URLQueryItem(name: "count", value: "\(count)"))
        }
        if let to = to {
            queryItems.append(URLQueryItem(name: "to", value: "\(Int(to.timeIntervalSince1970))"))
        }
        if let from = from {
            queryItems.append(URLQueryItem(name: "from", value: "\(Int(from.timeIntervalSince1970))"))
        }
        getMidgardResponse(completionHandler, midgardAPIURL: midgardAPIURL, endpoint: "/history/liquidity_changes", queryItems: queryItems)
    }
    
    
    /// GET all Nodes from Midgard API `/nodes`
    /// - Parameters:
    ///   - completionHandler: Called on main thread. Will contain an array of Midgard.Node's, or nil for any errors.
    ///   - midgardAPIURL: (optional) a URL for Midgard. If none specified, uses thorchain.info
    public func getMidgardNodes(_ completionHandler: @escaping ([Midgard.Node]?) -> (), midgardAPIURL: URL? = nil) {
        getMidgardResponse(completionHandler, midgardAPIURL: midgardAPIURL, endpoint: "/nodes")
    }
    
    
    /// GET all Network Data from Midgard API `/network`
    /// - Parameters:
    ///   - completionHandler: Called on main thread. Will contain a Midgard.NetworkData struct, or nil for any errors.
    ///   - midgardAPIURL: (optional) a URL for Midgard. If none specified, uses thorchain.info
    public func getMidgardNetworkData(_ completionHandler: @escaping (Midgard.NetworkData?) -> (), midgardAPIURL: URL? = nil) {
        getMidgardResponse(completionHandler, midgardAPIURL: midgardAPIURL, endpoint: "/network")
    }
    

    
    /// GET all actions along with their related transactions from Midgard API `/actions`
    /// - Parameters:
    ///   - limit: pagination limit. [0..50]
    ///   - offset: pagination offset (>= 0)
    ///   - address: Address of sender or recipient of any in/out transaction related to the action
    ///   - txid: ID of any in/out tx related to the action
    ///   - asset: Any asset that is part of the action (CHAIN.SYMBOL)
    ///   - type: One or more comma separated unique types of action (swap, addLiquidity, withdraw, donate, refund)
    ///   - completionHandler: Called on main thread. Will contain a Midgard.ActionsList struct, or nil for any errors.
    ///   - midgardAPIURL: (optional) a URL for Midgard. If none specified, uses thorchain.info
    public func getMidgardActions(limit : Int,
                                  offset : Int,
                                  address : String? = nil,
                                  txid : String? = nil,
                                  asset : String? = nil,
                                  type : [Midgard.ActionType] = [],
                                  _ completionHandler: @escaping (Midgard.ActionsList?) -> (),
                                  midgardAPIURL: URL? = nil) {
        assert(limit >= 0 && limit <= 50)
        assert(offset >= 0)
        var queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ]
        if let address = address {
            queryItems.append(URLQueryItem(name: "address", value: address))
        }
        if let txid = txid {
            queryItems.append(URLQueryItem(name: "txid", value: txid))
        }
        if let asset = asset {
            queryItems.append(URLQueryItem(name: "asset", value: asset))
        }
        if type.count > 0 {
            let value = (Set(type).map{$0.rawValue}).joined(separator: ",")
            queryItems.append(URLQueryItem(name: "type", value: value))
        }
        getMidgardResponse(completionHandler, midgardAPIURL: midgardAPIURL, endpoint: "/actions", queryItems: queryItems)
    }
    
    
    /// GET all Members from Midgard API `/members`
    /// - Parameters:
    ///   - pool: (optional) Return only members present in this pool, e.g. "BTC.BTC"
    ///   - completionHandler: Called on main thread. Will contain an array of Midgard.Member, or nil for any errors.
    ///   - midgardAPIURL: (optional) a URL for Midgard. If none specified, uses thorchain.info
    public func getMidgardMembers(pool : String? = nil,
                                  _ completionHandler: @escaping ([Midgard.Member]?) -> (),
                                  midgardAPIURL: URL? = nil) {
        let queryItems = pool != nil ? [URLQueryItem(name: "pool", value: pool!)] : []
        getMidgardResponse(completionHandler, midgardAPIURL: midgardAPIURL, endpoint: "/members", queryItems: queryItems)
    }
    
    
    
    /// GET Member Details from Midgard API `/member/{address}`
    /// - Parameters:
    ///   - address: Member address
    ///   - completionHandler: Called on main thread. Will contain a Midgard.MemberDetail struct, or nil for any errors.
    ///   - midgardAPIURL: (optional) a URL for Midgard. If none specified, uses thorchain.info
    public func getMidgardMember(address : String,
                                  _ completionHandler: @escaping (Midgard.MemberDetail?) -> (),
                                  midgardAPIURL: URL? = nil) {
        getMidgardResponse(completionHandler, midgardAPIURL: midgardAPIURL, endpoint: "/member/\(address)")
    }
    
    
    
    /// GET Global Stats from Midgard API `/stats`
    /// - Parameters:
    ///   - completionHandler: Called on main thread. Will contain a Midgard.GlobalStats struct, or nil for any errors.
    ///   - midgardAPIURL: (optional) a URL for Midgard. If none specified, uses thorchain.info
    public func getMidgardGlobalStats(_ completionHandler: @escaping (Midgard.GlobalStats?) -> (),midgardAPIURL: URL? = nil) {
        getMidgardResponse(completionHandler, midgardAPIURL: midgardAPIURL, endpoint: "/stats")
    }
    
    
    /// GET Thorchain Constants (proxied from Midgard API `/thorchain/constants`)
    /// - Parameters:
    ///   - completionHandler: Called on main thread. Will contain a Thorchain.Constants struct, or nil for any errors.
    ///   - midgardAPIURL: (optional) a URL for Midgard. If none specified, uses thorchain.info
    public func getThorchainConstants(_ completionHandler: @escaping (Thorchain.Constants?) -> (),midgardAPIURL: URL? = nil) {
        getMidgardResponse(completionHandler, midgardAPIURL: midgardAPIURL, endpoint: "/thorchain/constants")
    }
    
    
    /// GET Thorchain Latest block information across all chains (proxied from Midgard API `/thorchain/lastblock`)
    /// - Parameters:
    ///   - completionHandler: Called on main thread. Will contain a Thorchain.LastBlock struct, or nil for any errors.
    ///   - midgardAPIURL: (optional) a URL for Midgard. If none specified, uses thorchain.info
    public func getThorchainLastBlock(_ completionHandler: @escaping ([Thorchain.LastBlock]?) -> (),midgardAPIURL: URL? = nil) {
        getMidgardResponse(completionHandler, midgardAPIURL: midgardAPIURL, endpoint: "/thorchain/lastblock")
    }
    
    
    /// GET Thorchain Queue (proxied from Midgard API `/thorchain/queue`)
    /// - Parameters:
    ///   - completionHandler: Called on main thread. Will contain a Thorchain.Queue struct, or nil for any errors.
    ///   - midgardAPIURL: (optional) a URL for Midgard. If none specified, uses thorchain.info
    public func getThorchainQueue(_ completionHandler: @escaping (Thorchain.Queue?) -> (),midgardAPIURL: URL? = nil) {
        getMidgardResponse(completionHandler, midgardAPIURL: midgardAPIURL, endpoint: "/thorchain/queue")
    }
    
}


// Special handling of Inbound_Addresses by querying multiple endpoints
extension Thorchain {
    enum SwapError: Error, LocalizedError {
        case noAnyResponses
        case sameAssets
        case inboundAddressesNotFound
        case inboundAddressesNotMatch
        case cantFoundFromAsset
        case cantFoundPool(memo: String)
        case poolNotActive(asset: String)
        case routerNotSupported
        case notValidRouterAddress

        public var errorDescription: String? {
            switch self {
            case .noAnyResponses: return "Could not found any Inbound Addresses responses"
            case .sameAssets: return "fromAsset and toAsset are the same"
            case .inboundAddressesNotFound: return "Inbound Addresses not found"
            case .inboundAddressesNotMatch: return "Inbound Addresses not match"
            case .cantFoundFromAsset: return "Could not find Midgard from asset's pool"
            case .cantFoundPool(let memo): return "Could not find Midgard pool for \(memo)"
            case .poolNotActive(let asset): return "Pool not Active \(asset)"
            case .routerNotSupported: return "Only ETH Routers supported (tested)"
            case .notValidRouterAddress: return "Not Valid Router Address"
            }
        }
    }

    public func getInboundAddresses() async throws -> [Midgard.InboundAddress] {
        let trustedMidgardURLs = (additionalTrustedMidgardURLs + chain.urls)
            .map{ $0.appendingPathComponent("/thorchain/inbound_addresses") }

        return try await withThrowingTaskGroup(of: [Midgard.InboundAddress].self) { group in
            for url in trustedMidgardURLs {
                group.addTask {
                    let addresses: [Midgard.InboundAddress] = try await self.networkManager.fetchArray(url: url)
                    return addresses
                }
            }

            var responses = [[Midgard.InboundAddress]]()

            for try await addresses in group {
                responses.append(addresses.filter { !($0.halted ?? false) })
            }

            guard let firstResponse = responses.first else {
                throw SwapError.noAnyResponses
            }

            let allMatch: Bool = responses.count >= 2 && responses.dropFirst().allSatisfy { $0.same(firstResponse) }
            if allMatch {
                // All success. Store latest result and signal completion handler also with latest result.
                latestAddressesStored = (firstResponse, Date())
                return firstResponse
            }

            self.debugLog("Thorchain: Inbound Addresses from various nodes do not match. Aborting")
            throw SwapError.inboundAddressesNotMatch
        }
    }

    public func getInboundAddresses(_ completionHandler : @escaping ([Midgard.InboundAddress]?) -> ()) {
        let dispatchGroup = DispatchGroup()
        var validResponses = [[Midgard.InboundAddress]]()
        let trustedMidgardURLs = (additionalTrustedMidgardURLs + chain.urls)
            .map{ $0.appendingPathComponent("/thorchain/inbound_addresses") }

        for midgardURL in trustedMidgardURLs {
            dispatchGroup.enter()
            // Midgard Network Request each node and store valid responses
            let inboundAddressDataTask = urlSession.dataTask(with: midgardURL) { (data, response, error) in
                defer {
                    dispatchGroup.leave()
                }
                guard let data = data, error == nil else {
                    if let error = error { print("Thorchain Error: \(error)") }
                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                        print("Thorchain Error: HTTP \(httpResponse.statusCode) from \(midgardURL.absoluteString)")
                    }
                    return
                }
                if let activeInboundAddresses : [Midgard.InboundAddress] = try? self.jsonDecoder.decode([Midgard.InboundAddress].self, from: data)
                    .filter({ $0.halted ?? false == false }) {

                    validResponses.append(activeInboundAddresses)
                }
            }
            inboundAddressDataTask.resume()
        }

        dispatchGroup.notify(queue: .main) {
            // All network requests complete (or failed / timed out)
            // Check all returned InboundAddress' are the same

            let allMatch : Bool = validResponses.count >= 2 && validResponses.dropFirst().allSatisfy{ $0.same(validResponses.first ?? []) }
            if allMatch, let activeAddresses = validResponses.first {
                // All success. Store latest result and signal completion handler also with latest result.
                self.latestAddressesStored = (activeAddresses, Date())
                completionHandler(activeAddresses)
            } else {
                self.debugLog("Thorchain: Inbound Addresses from various nodes do not match. Aborting")
                completionHandler(nil)
            }
        }
    }
}
