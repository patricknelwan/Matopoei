import UIKit

class ComicCell: UICollectionViewCell {
    
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let progressView = UIProgressView()
    private let pageCountLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        contentView.backgroundColor = .clear
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        
        titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.textColor = .label
        
        pageCountLabel.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        pageCountLabel.textAlignment = .center
        pageCountLabel.textColor = .secondaryLabel
        
        progressView.progressTintColor = .systemBlue
        progressView.trackTintColor = .systemGray4
        
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(pageCountLabel)
        contentView.addSubview(progressView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        pageCountLabel.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            // Fixed height instead of aspect ratio to avoid constraint conflicts
            imageView.heightAnchor.constraint(equalToConstant: 240),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            
            pageCountLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            pageCountLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            pageCountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            
            progressView.topAnchor.constraint(equalTo: pageCountLabel.bottomAnchor, constant: 4),
            progressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2),
            progressView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func configure(with comic: ComicBook) {
        titleLabel.text = comic.title
        pageCountLabel.text = "\(comic.totalPages) pages"
        
        // Set cover image
        if let coverImage = comic.coverImage {
            imageView.image = coverImage
        } else {
            imageView.image = UIImage(systemName: "book.closed.fill")
            imageView.tintColor = .systemGray3
        }
        
        // Update progress
        let progress = comic.totalPages > 0 ? Float(comic.currentPageIndex + 1) / Float(comic.totalPages) : 0.0
        progressView.progress = progress
        progressView.isHidden = (progress == 0)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        titleLabel.text = nil
        pageCountLabel.text = nil
        progressView.progress = 0
        progressView.isHidden = true
    }
}
