import Foundation
import RealmSwift

class HeaderHandler {
    enum HandleError: Error {
        case emptyHeaders
    }

    let realmFactory: RealmFactory
    let factory: Factory
    let validator: BlockValidator
    let blockSyncer: BlockSyncer
    let network: NetworkProtocol

    init(realmFactory: RealmFactory, factory: Factory, validator: BlockValidator, blockSyncer: BlockSyncer, network: NetworkProtocol) {
        self.realmFactory = realmFactory
        self.factory = factory
        self.validator = validator
        self.blockSyncer = blockSyncer
        self.network = network
    }

    func handle(headers: [BlockHeader]) throws {
        let realm = realmFactory.realm

        guard !headers.isEmpty else {
            throw HandleError.emptyHeaders
        }

        let validBlocks = getValidBlocks(headers: headers, realm: realm)

        if !validBlocks.blocks.isEmpty {
            try realm.write {
                for block in validBlocks.blocks {
                    if let existingBlock = realm.objects(Block.self).filter("reversedHeaderHashHex = %@", block.reversedHeaderHashHex).first {
                        if existingBlock.header == nil {
                            existingBlock.header = block.header
                        }
                    } else {
                        realm.add(block)
                    }
                }
            }

            blockSyncer.enqueueRun()
        }

        if let validationError = validBlocks.error {
            throw validationError
        }
    }

    func getValidBlocks(headers: [BlockHeader], realm: Realm) -> (blocks: [Block], error: Error?) {
        let blockInChain = realm.objects(Block.self).filter("previousBlock != nil").sorted(byKeyPath: "height")
        let initialBlock = blockInChain.last ?? network.checkpointBlock

        var newBlocks = [Block]()
        var previousBlock = initialBlock

        for header in headers {
            let block = factory.block(withHeader: header, previousBlock: previousBlock)
            newBlocks.append(block)

            previousBlock = block
        }

        var validBlocks = [Block]()

        var validationError: Error?

        do {
            for newBlock in newBlocks {
                try validator.validate(block: newBlock)
                validBlocks.append(newBlock)
            }
        } catch {
            validationError = error
        }

        return (validBlocks, validationError)
    }

}
