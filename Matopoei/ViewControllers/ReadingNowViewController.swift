import UIKit

class ReadingNowViewController: UIViewController {
    
    private var tableView: UITableView!
    private var currentlyReading: [ComicBook] = []
    private let comicStorage = ComicStorage()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadCurrentlyReading()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadCurrentlyReading()
    }
    
    private func setupUI() {
        title = "Reading Now"
        view.backgroundColor = .systemBackground
        
        tableView = UITableView(frame: view.bounds)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CurrentlyReadingCell.self, forCellReuseIdentifier: "ReadingCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadCurrentlyReading() {
        let allComics = comicStorage.loadComics()
        // Show comics with reading progress (not finished)
        currentlyReading = allComics.filter { comic in
            comic.currentPageIndex > 0 && comic.currentPageIndex < comic.totalPages - 1
        }.sorted { $0.lastReadDate > $1.lastReadDate }
        
        tableView.reloadData()
        
        if currentlyReading.isEmpty {
            showEmptyState()
        }
    }
    
    private func showEmptyState() {
        let emptyView = createEmptyStateView()
        tableView.backgroundView = emptyView
    }
    
    private func createEmptyStateView() -> UIView {
        let containerView = UIView()
        
        let imageView = UIImageView(image: UIImage(systemName: "book.closed"))
        imageView.tintColor = .systemGray3
        imageView.contentMode = .scaleAspectFit
        
        let titleLabel = UILabel()
        titleLabel.text = "No Comics in Progress"
        titleLabel.font = .boldSystemFont(ofSize: 22)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Start reading a comic to see it here"
        subtitleLabel.font = .systemFont(ofSize: 16)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        
        containerView.addSubview(imageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    private func continueReading(_ comic: ComicBook) {
        let readerVC = ComicReaderViewController()
        readerVC.comic = comic
        readerVC.modalPresentationStyle = .fullScreen
        present(readerVC, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension ReadingNowViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentlyReading.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReadingCell", for: indexPath) as! CurrentlyReadingCell
        let comic = currentlyReading[indexPath.row]
        cell.configure(with: comic)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let comic = currentlyReading[indexPath.row]
        continueReading(comic)
    }
}
