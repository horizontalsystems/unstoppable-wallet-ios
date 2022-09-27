import Foundation
import RxSwift
import RxRelay
import MarketKit

class NftMetadataService {
    private let nftMetadataManager: NftMetadataManager
    private let disposeBag = DisposeBag()

    private let assetsBriefMetadataRelay = PublishRelay<[NftUid: NftAssetBriefMetadata]>()

    init(nftMetadataManager: NftMetadataManager) {
        self.nftMetadataManager = nftMetadataManager
    }

    private func handle(assetsBriefMetadata: [NftAssetBriefMetadata]) {
        nftMetadataManager.save(assetsBriefMetadata: assetsBriefMetadata)

        let map = Dictionary(uniqueKeysWithValues: assetsBriefMetadata.map { ($0.nftUid, $0) })
        assetsBriefMetadataRelay.accept(map)
    }

}

extension NftMetadataService {

    var assetsBriefMetadataObservable: Observable<[NftUid: NftAssetBriefMetadata]> {
        assetsBriefMetadataRelay.asObservable()
    }

    func assetsBriefMetadata(nftUids: Set<NftUid>) -> [NftUid: NftAssetBriefMetadata] {
        let array = nftMetadataManager.assetsBriefMetadata(nftUids: nftUids)
        return Dictionary(uniqueKeysWithValues: array.map { ($0.nftUid, $0) })
    }

    func fetch(nftUids: Set<NftUid>) {
        nftMetadataManager.assetsBriefMetadataSingle(nftUids: nftUids)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onSuccess: { [weak self] assetsBriefMetadata in
                    self?.handle(assetsBriefMetadata: assetsBriefMetadata)
                })
                .disposed(by: disposeBag)
    }

}
