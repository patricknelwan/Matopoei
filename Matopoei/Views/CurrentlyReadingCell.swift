import UIKit

class CurrentlyReadingCell: UITableViewCell {
    
    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray6
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.numberOfLines = 2
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = .systemBlue
        progress.trackTintColor = .systemGray4
        progress.translatesAutoresizingMaskIntoConstraints = false
        return progress
    }()
    
    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Continue", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        selectionStyle = .none
        
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(progressView)
        contentView.addSubview(continueButton)
        
        // Fixed constraints - remove conflicting height constraint
        NSLayoutConstraint.activate([
            // Thumbnail - use flexible constraints instead of fixed height
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            thumbnailImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 60),
            // Remove fixed height - let it be flexible
            thumbnailImageView.heightAnchor.constraint(lessThanOrEqualToConstant: 90),
            
            // Title
            titleLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: continueButton.leadingAnchor, constant: -8),
            
            // Subtitle
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            // Progress bar
            progressView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            progressView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 8),
            progressView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            progressView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16),
            
            // Continue button
            continueButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            continueButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            continueButton.widthAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    func configure(with comic: ComicBook) {
        titleLabel.text = comic.title
        
        // Set cover image
        if let coverImage = comic.coverImage {
            thumbnailImageView.image = coverImage
        } else {
            thumbnailImageView.image = UIImage(systemName: "book.fill")
            thumbnailImageView.tintColor = .systemGray3
        }
        
        // Set progress info
        let progress = comic.totalPages > 0 ? Float(comic.currentPageIndex + 1) / Float(comic.totalPages) : 0
        progressView.setProgress(progress, animated: false)
        
        let progressText = "Page \(comic.currentPageIndex + 1) of \(comic.totalPages)"
        subtitleLabel.text = progressText
    }
}
