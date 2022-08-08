import UIKit
import ComponentKit

class TweetAttachmentView: UIView {
    private static let imageAttachmentHeight: CGFloat = 180

    private let imageView = UIImageView()
    private let imageTransparencyView = UIView()
    private let videoPlayImageView = UIImageView()
    private let pollView = TweetPollView()

    init() {
        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(imageView)

        imageView.cornerRadius = .cornerRadius4
        imageView.layer.cornerCurve = .continuous
        imageView.contentMode = .scaleAspectFill

        imageView.addSubview(imageTransparencyView)
        imageTransparencyView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        
        imageTransparencyView.cornerRadius = .cornerRadius4
        imageTransparencyView.layer.cornerCurve = .continuous
        imageTransparencyView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        
        imageView.addSubview(videoPlayImageView)
        videoPlayImageView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.width.equalTo(48)
        }
        
        videoPlayImageView.image = UIImage(named: "play_48")?.withTintColor(.white)

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
        imageView.kf.setImage(with: URL(string: url))

        pollView.snp.removeConstraints()
        imageView.snp.remakeConstraints { maker in
            maker.edges.equalToSuperview()
            maker.height.equalTo(Self.imageAttachmentHeight)
        }

        imageView.isHidden = false
        videoPlayImageView.isHidden = true
        imageTransparencyView.isHidden = true
        pollView.isHidden = true
    }

    private func bindVideo(previewImageUrl: String) {
        imageView.kf.setImage(with: URL(string: previewImageUrl))

        pollView.snp.removeConstraints()
        imageView.snp.remakeConstraints { maker in
            maker.edges.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.equalTo(Self.imageAttachmentHeight)
        }

        imageView.isHidden = false
        videoPlayImageView.isHidden = false
        imageTransparencyView.isHidden = false
        pollView.isHidden = true
    }

    private func bindPoll(options: [(position: Int, label: String, votes: Int)]) {
        imageView.snp.removeConstraints()
        pollView.snp.remakeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        imageView.isHidden = true
        pollView.isHidden = false

        pollView.bind(options: options)
    }

    static func height(attachment: Tweet.Attachment, containerWidth: CGFloat) -> CGFloat {
        switch attachment {
        case .photo, .video: return Self.imageAttachmentHeight
        case .poll(let options): return TweetPollView.height(options: options, containerWidth: containerWidth)
        }
    }

}
