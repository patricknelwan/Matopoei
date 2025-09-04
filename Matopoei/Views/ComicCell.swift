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
        contentView.layer.cornerRadius = 12
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.15
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 8
        contentView.backgroundColor = .systemBackground
        
        // Image view setup
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray5
        
        // Title label setup
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.textColor = .label
        
        // Page count label setup
        pageCountLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        pageCountLabel.textAlignment = .center
        pageCountLabel.textColor = .secondaryLabel
        
        // Progress view setup
        progressView.progressTintColor = .systemBlue
        progressView.trackTintColor = .systemGray4
        progressView.layer.cornerRadius = 2
        
        // Add subviews
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(pageCountLabel)
        contentView.addSubview(progressView)
        
        // Auto Layout
        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        pageCountLabel.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            imageView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.65),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            
            pageCountLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            pageCountLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            pageCountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            
            progressView.topAnchor.constraint(equalTo: pageCountLabel.bottomAnchor, constant: 8),
            progressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            progressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            progressView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8)
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
