import UIKit
import ComponentKit

class TweetAttachmentView: UIView {

    private let imageView = UIImageView()
    private let videoPlayImageView = UIImageView()
    private let pollView = TweetPollView()

    init() {
        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(imageView)
        imageView.cornerRadius = 4
        imageView.contentMode = .scaleAspectFill

        imageView.addSubview(videoPlayImageView)
        videoPlayImageView.image = UIImage(named: "play_48")

        addSubview(pollView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(attachment: Tweet.Attachment) {
        switch attachment {
        case .photo(let url): bindPhoto(url: url)
        case .video(let previewImageUrl): bindVideo(previewImageUrl: previewImageUrl)
        case .poll(let options): bindPoll(options: options)
        }
    }

    private func bindPhoto(url: String) {
        imageView.af.cancelImageRequest()
        if let url = URL(string: url) {
            imageView.af.setImage(withURL: url)
        }

        imageView.snp.remakeConstraints { maker in
            maker.edges.equalToSuperview()
            maker.width.equalToSuperview()
        }

        imageView.isHidden = false
        videoPlayImageView.isHidden = true
        pollView.isHidden = true
    }

    private func bindVideo(previewImageUrl: String) {
        imageView.af.cancelImageRequest()
        if let url = URL(string: previewImageUrl) {
            imageView.af.setImage(withURL: url)
        }

        imageView.snp.remakeConstraints { maker in
            maker.edges.equalToSuperview()
            maker.width.equalToSuperview()
        }

        videoPlayImageView.snp.remakeConstraints { maker in
            maker.center.equalToSuperview()
            maker.width.equalTo(48)
        }

        imageView.isHidden = false
        videoPlayImageView.isHidden = false
        pollView.isHidden = true
    }

    private func bindPoll(options: [(position: Int, label: String, votes: Int)]) {
        pollView.bind(options: options)
        pollView.snp.remakeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        imageView.isHidden = true
        pollView.isHidden = false
    }

    static func height(attachment: Tweet.Attachment, containerWidth: CGFloat) -> CGFloat {
        switch attachment {
        case .photo, .video: return 180
        case .poll(let options): return TweetPollView.height(options: options, containerWidth: containerWidth)
        }
    }

}
