import UIKit
import ComponentKit

class TweetAttachmentView: UIView {

    private let imageView = UIImageView()
    private let imageTransparencyView = UIView()
    private let videoPlayImageView = UIImageView()
    private let pollView = TweetPollView()

    init() {
        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.equalTo(180)
        }
        
        imageView.cornerRadius = 4
        imageView.contentMode = .scaleAspectFill

        imageView.addSubview(imageTransparencyView)
        imageTransparencyView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        
        imageTransparencyView.cornerRadius = 4
        imageTransparencyView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        
        imageView.addSubview(videoPlayImageView)
        videoPlayImageView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.width.equalTo(48)
        }
        
        videoPlayImageView.image = UIImage(named: "play_48")?.withTintColor(.white)

        addSubview(pollView)
        pollView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
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

        imageView.isHidden = false
        videoPlayImageView.isHidden = true
        imageTransparencyView.isHidden = true
        pollView.isHidden = true
    }

    private func bindVideo(previewImageUrl: String) {
        imageView.af.cancelImageRequest()
        if let url = URL(string: previewImageUrl) {
            imageView.af.setImage(withURL: url)
        }

        imageView.isHidden = false
        videoPlayImageView.isHidden = false
        imageTransparencyView.isHidden = false
        pollView.isHidden = true
    }

    private func bindPoll(options: [(position: Int, label: String, votes: Int)]) {
        pollView.bind(options: options)
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
