import Foundation

class Peer : NSObject, StreamDelegate {
    private let protocolVersion: Int32 = 70015
    private let bufferSize = 4096

    private let host: String
    private let port: UInt32
    private let network: NetworkProtocol

    weak var delegate: PeerDelegate?

    private let queue: DispatchQueue
    private var runLoop: RunLoop?

    private var readStream: Unmanaged<CFReadStream>?
    private var writeStream: Unmanaged<CFWriteStream>?
    private var inputStream: InputStream?
    private var outputStream: OutputStream?

    private var packets = Data()

    private var sentVersion = false
    private var sentVerack = false
//    var sentFilterLoad = false
//    var sentMemPool = false

    convenience init(network: NetworkProtocol = TestNet()) {
        self.init(host: network.dnsSeeds[2], port: Int(network.port), network: network)
    }

    convenience init(host: String, network: NetworkProtocol = TestNet()) {
        self.init(host: host, port: Int(network.port), network: network)
    }

    init(host: String, port: Int, network: NetworkProtocol = TestNet()) {
        self.host = host
        self.port = UInt32(port)
        self.network = network

        queue = DispatchQueue(label: host, qos: .background)
    }

    deinit {
        disconnect()
    }

    func connect() {
        if runLoop == nil {
            queue.async {
                self.runLoop = .current
                self.connectAsync()
            }
        } else {
            print("ALREADY CONNECTED")
        }
    }

    private func connectAsync() {
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, host as CFString, port, &readStream, &writeStream)
        inputStream = readStream!.takeRetainedValue()
        outputStream = writeStream!.takeRetainedValue()

        inputStream?.delegate = self
        outputStream?.delegate = self

        inputStream?.schedule(in: .current, forMode: .commonModes)
        outputStream?.schedule(in: .current, forMode: .commonModes)

        inputStream?.open()
        outputStream?.open()

        RunLoop.current.run()
    }

    func disconnect() {
        guard readStream != nil && readStream != nil else {
            return
        }

        inputStream?.delegate = nil
        outputStream?.delegate = nil
        inputStream?.close()
        outputStream?.close()
        inputStream?.remove(from: .current, forMode: .commonModes)
        outputStream?.remove(from: .current, forMode: .commonModes)
        readStream = nil
        writeStream = nil

        runLoop = nil

        sentVersion = false
        sentVerack = false

        log("DISCONNECTED")
    }

    func stream(_ stream: Stream, handle eventCode: Stream.Event) {
        switch stream {
        case let stream as InputStream:
            switch eventCode {
            case .openCompleted:
                log("CONNECTED")
                break
            case .hasBytesAvailable:
                readAvailableBytes(stream: stream)
            case .hasSpaceAvailable:
                break
            case .errorOccurred:
                log("IN ERROR OCCURRED")
                disconnect()
            case .endEncountered:
                log("IN CLOSED")
                disconnect()
            default:
                break
            }
        case _ as OutputStream:
            switch eventCode {
            case .openCompleted:
                break
            case .hasBytesAvailable:
                break
            case .hasSpaceAvailable:
                if !sentVersion {
                    sendVersionMessage()
                    sentVersion = true
                }
            case .errorOccurred:
                log("OUT ERROR OCCURRED")
                disconnect()
            case .endEncountered:
                log("OUT CLOSED")
                disconnect()
            default:
                break
            }
        default:
            break
        }
    }

    private func readAvailableBytes(stream: InputStream) {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)

        defer { buffer.deallocate() }

        while stream.hasBytesAvailable {
            let numberOfBytesRead = stream.read(buffer, maxLength: bufferSize)
            if numberOfBytesRead <= 0 {
                if let _ = stream.streamError {
                    break
                }
            } else {
                packets += Data(bytesNoCopy: buffer, count: numberOfBytesRead, deallocator: .none)
            }
        }

        while packets.count >= Message.minimumLength {
            guard let message = Message.deserialize(packets) else {
                return
            }

            autoreleasepool {
                packets = Data(packets.dropFirst(Message.minimumLength + Int(message.length)))
                switch message.command {
                case "version":
                    handle(versionMessage: VersionMessage.deserialize(message.payload))
                case "verack":
                    handleVerackMessage()
                case "addr":
                    handle(addressMessage: AddressMessage.deserialize(message.payload))
                case "inv":
                    handle(inventoryMessage: InventoryMessage.deserialize(message.payload))
                case "headers":
                    handle(headersMessage: HeadersMessage.deserialize(message.payload))
                case "getdata":
                    handle(getDataMessage: GetDataMessage.deserialize(message.payload))
                case "notfound":
                    break
                case "block":
                    handle(blockMessage: BlockMessage.deserialize(message.payload))
                case "merkleblock":
                    handle(merkleBlockMessage: MerkleBlockMessage.deserialize(message.payload))
                case "tx":
                    handle(transaction: Transaction.deserialize(message.payload))
                case "ping":
                    handle(pingMessage: PingMessage.deserialize(message.payload))
                case "reject":
                    handle(rejectMessage: RejectMessage.deserialize(message.payload))
                default:
                    break
                }
            }
        }
    }

//    public func startSync(filters: [Data] = [], latestBlockHash: Data) {
////        self.latestBlockHash = latestBlockHash
////        context.isSyncing = true
//
//        if !self.context.sentFilterLoad {
//            sendFilterLoadMessage(filters: filters)
//            self.context.sentFilterLoad = true
////            if !self.context.sentMemPool {
////                self.sendMemoryPoolMessage()
////                self.context.sentMemPool = true
////            }
//        }
////        self.sendGetBlocksMessage()
//    }

    func load(filters: [Data]) {
        sendFilterLoadMessage(filters: filters)
    }

    private func send(messageWithCommand command: String, payload: Data) {
        let checksum = Data(Crypto.sha256sha256(payload).prefix(4))
        let message = Message(magic: network.magic, command: command, length: UInt32(payload.count), checksum: checksum, payload: payload)

        let data = message.serialized()
        _ = data.withUnsafeBytes {
            outputStream?.write($0, maxLength: data.count)
        }
    }

    private func sendVersionMessage() {
        let versionMessage = VersionMessage(
                version: protocolVersion,
                services: 0x00,
                timestamp: Int64(Date().timeIntervalSince1970),
                yourAddress: NetworkAddress(services: 0x00, address: "::ffff:127.0.0.1", port: UInt16(port)),
                myAddress: NetworkAddress(services: 0x00, address: "::ffff:127.0.0.1", port: UInt16(port)),
                nonce: 0,
                userAgent: "/WalletKit:0.1.0/",
                startHeight: -1,
                relay: false
        )

        log("<-- VERSION: \(versionMessage.version) --- \(versionMessage.userAgent?.value ?? "") --- \(ServiceFlags(rawValue: versionMessage.services))")
        send(messageWithCommand: "version", payload: versionMessage.serialized())
    }

    private func sendVerackMessage() {
        log("<-- VERACK")
        send(messageWithCommand: "verack", payload: Data())
    }

    private func sendFilterLoadMessage(filters: [Data]) {
        guard !filters.isEmpty else {
            return
        }

        let nTweak = arc4random_uniform(UInt32.max)
        var filter = BloomFilter(elements: filters.count, falsePositiveRate: 0.00005, randomNonce: nTweak)

        for f in filters {
            filter.insert(f)
        }

        let filterData = Data(filter.data)
        let filterLoadMessage = FilterLoadMessage(filter: filterData, nHashFuncs: filter.nHashFuncs, nTweak: nTweak, nFlags: 0)

        log("<-- FILTERLOAD: \(filters.count) item(s)")
        send(messageWithCommand: "filterload", payload: filterLoadMessage.serialized())
    }

    func sendMemoryPoolMessage() {
        log("<-- MEMPOOL")
        send(messageWithCommand: "mempool", payload: Data())
    }

//    private func sendGetBlocksMessage() {
//        let blockLocatorHash = latestBlockHash
//        let getBlocks = GetBlocksMessage(version: UInt32(protocolVersion), hashCount: 1, blockLocatorHashes: blockLocatorHash, hashStop: Data(count: 32))
//
//        let payload = getBlocks.serialized()
//        let checksum = Data(Crypto.sha256sha256(payload).prefix(4))
//
//        let message = Message(magic: network.magic, command: "getblocks", length: UInt32(payload.count), checksum: checksum, payload: payload)
//        sendMessage(message)
//    }

    func sendGetHeadersMessage(headerHashes: [Data]) {
        let getHeadersMessage = GetBlocksMessage(version: UInt32(protocolVersion), hashCount: VarInt(headerHashes.count), blockLocatorHashes: headerHashes, hashStop: Data(count: 32))

        log("<-- GETHEADERS: \(headerHashes.count) header hashes")
        send(messageWithCommand: "getheaders", payload: getHeadersMessage.serialized())
    }

    func sendGetDataMessage(message: InventoryMessage) {
        log("<-- GETDATA: \(message.inventoryItems.count) item(s)")
        send(messageWithCommand: "getdata", payload: message.serialized())
    }

    func send(inventoryMessage: InventoryMessage) {
        log("<-- INV: \(inventoryMessage.inventoryItems.first?.hash.reversedHex ?? "UNKNOWN")")
        send(messageWithCommand: "inv", payload: inventoryMessage.serialized())
    }

    func sendTransaction(transaction: Transaction) {
        log("<-- TX: \(transaction.reversedHashHex)")
        send(messageWithCommand: "tx", payload: transaction.serialized())
    }

    private func handle(versionMessage: VersionMessage) {
        log("--> VERSION: \(versionMessage.version) --- \(versionMessage.userAgent?.value ?? "") --- \(ServiceFlags(rawValue: versionMessage.services))")

        delegate?.peer(self, didReceiveVersionMessage: versionMessage)

        if !sentVerack {
            sendVerackMessage()
            sentVerack = true
        }
    }

    private func handleVerackMessage() {
        log("--> VERACK")
        delegate?.peerDidConnect(self)
    }

    private func handle(addressMessage: AddressMessage) {
        log("--> ADDR: \(addressMessage.count) address(es)")
        delegate?.peer(self, didReceiveAddressMessage: addressMessage)
    }

    private func handle(inventoryMessage: InventoryMessage) {
        log("--> INV: \(inventoryMessage.count) item(s)")
        delegate?.peer(self, didReceiveInventoryMessage: inventoryMessage)
    }

    private func handle(headersMessage: HeadersMessage) {
        log("--> HEADERS: \(headersMessage.count) item(s)")
        delegate?.peer(self, didReceiveHeadersMessage: headersMessage)
    }

    private func handle(getDataMessage: GetDataMessage) {
        log("--> GETDATA: \(getDataMessage.count) item(s)")
        delegate?.peer(self, didReceiveGetDataMessage: getDataMessage)
    }

    private func handle(blockMessage: BlockMessage) {
        log("--> BLOCK: \(Crypto.sha256sha256(blockMessage.blockHeaderItem.serialized()).reversedHex)")

//        let block = BlockMessage.deserialize(payload)
//        let blockHash = Data(Crypto.sha256sha256(payload.prefix(80)).reversed())
//        delegate?.peer(self, didReceiveBlockMessage: block, hash: blockHash)
//
//        context.inventoryItems[blockHash] = nil
//        if context.inventoryItems.isEmpty {
//            latestBlockHash = blockHash
//            sendGetBlocksMessage()
//        }
    }

    private func handle(merkleBlockMessage: MerkleBlockMessage) {
        log("--> MERKLEBLOCK: \(Crypto.sha256sha256(merkleBlockMessage.blockHeader.serialized()).reversedHex)")
        delegate?.peer(self, didReceiveMerkleBlockMessage: merkleBlockMessage)
    }

    private func handle(transaction: Transaction) {
        log("--> TX: \(Crypto.sha256sha256(transaction.serialized()).reversedHex)")
        delegate?.peer(self, didReceiveTransaction: transaction)
    }

    private func handle(pingMessage: PingMessage) {
        log("--> PING")

        let pongMessage = PongMessage(nonce: pingMessage.nonce)

        log("<-- PONG")
        send(messageWithCommand: "pong", payload: pongMessage.serialized())
    }

    private func handle(rejectMessage: RejectMessage) {
        log("--> REJECT: \(rejectMessage.message) code: 0x\(String(rejectMessage.ccode, radix: 16)) reason: \(rejectMessage.reason)")
        delegate?.peer(self, didReceiveRejectMessage: rejectMessage)
    }

    private func log(_ message: String) {
        print("\(host):\(port) \(message)")
    }
}

protocol PeerDelegate : class {
    func peerDidConnect(_ peer: Peer)
    func peerDidDisconnect(_ peer: Peer)
    func peer(_ peer: Peer, didReceiveVersionMessage message: VersionMessage)
    func peer(_ peer: Peer, didReceiveAddressMessage message: AddressMessage)
    func peer(_ peer: Peer, didReceiveGetDataMessage message: GetDataMessage)
    func peer(_ peer: Peer, didReceiveInventoryMessage message: InventoryMessage)
    func peer(_ peer: Peer, didReceiveHeadersMessage message: HeadersMessage)
    func peer(_ peer: Peer, didReceiveBlockMessage message: BlockMessage)
    func peer(_ peer: Peer, didReceiveMerkleBlockMessage message: MerkleBlockMessage)
    func peer(_ peer: Peer, didReceiveTransaction transaction: Transaction)
    func peer(_ peer: Peer, didReceiveRejectMessage message: RejectMessage)
}

extension PeerDelegate {
    func peerDidConnect(_ peer: Peer) {}
    func peerDidDisconnect(_ peer: Peer) {}
    func peer(_ peer: Peer, didReceiveVersionMessage message: VersionMessage) {}
    func peer(_ peer: Peer, didReceiveAddressMessage message: AddressMessage) {}
    func peer(_ peer: Peer, didReceiveGetDataMessage message: GetDataMessage) {}
    func peer(_ peer: Peer, didReceiveInventoryMessage message: InventoryMessage) {}
    func peer(_ peer: Peer, didReceiveHeadersMessage message: HeadersMessage) {}
    func peer(_ peer: Peer, didReceiveBlockMessage message: BlockMessage) {}
    func peer(_ peer: Peer, didReceiveMerkleBlockMessage message: MerkleBlockMessage) {}
    func peer(_ peer: Peer, didReceiveTransaction transaction: Transaction) {}
    func peer(_ peer: Peer, didReceiveRejectMessage message: RejectMessage) {}
}
