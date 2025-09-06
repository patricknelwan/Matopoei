import UIKit

class LibraryViewController: UIViewController {
    
    private var collectionView: UICollectionView!
    private var comics: [ComicBook] = []
    private let comicImporter = ComicImporter()
    private let comicStorage = ComicStorage()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupUI()
        loadComics()
        
        // Update layout when device rotates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationDidChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    @objc private func orientationDidChange() {
        DispatchQueue.main.async {
            let newLayout = self.createCollectionViewLayout()
            self.collectionView.setCollectionViewLayout(newLayout, animated: true)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }
    
    private func cleanupBrokenComics() {
        let comics = comicStorage.loadComics()
        let validComics = comics.filter { comic in
            return FileManager.default.fileExists(atPath: comic.fileURL.path)
        }
        
        if validComics.count != comics.count {
            print("Removed \(comics.count - validComics.count) comics with broken file paths")
            comicStorage.saveComics(validComics)
        }
    }
    
    private func setupCollectionView() {
        let layout = createCollectionViewLayout()
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .systemBackground
        collectionView.register(ComicCell.self, forCellWithReuseIdentifier: "ComicCell")
        
        view.addSubview(collectionView)
    }
    
    private func setupUI() {
        title = "Matopoe"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemBackground
        
        comicImporter.delegate = self
        
        // Add import button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(importButtonTapped)
        )
        
        // Add settings button with menu
        let settingsMenu = UIMenu(title: "", children: [
            UIAction(title: "Sort by Title", image: UIImage(systemName: "textformat.abc")) { _ in
                self.sortComics(by: .title)
            },
            UIAction(title: "Sort by Date Added", image: UIImage(systemName: "calendar")) { _ in
                self.sortComics(by: .dateAdded)
            },
            UIAction(title: "Clear Library", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self.confirmClearLibrary()
            }
        ])
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            primaryAction: nil,
            menu: settingsMenu
        )
    }
    
    private func createCollectionViewLayout() -> UICollectionViewLayout {
        let isLandscape = view.bounds.width > view.bounds.height
        let columnsCount = isLandscape ? 4 : 3
        
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0 / CGFloat(columnsCount)),
            heightDimension: .absolute(320) // MUST be .absolute, NOT .estimated
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        // NO contentInsets on item!
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(320)
        )
        
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            repeatingSubitem: item,
            count: columnsCount
        )
        group.interItemSpacing = .fixed(8)
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 16, bottom: 20, trailing: 16)
        section.interGroupSpacing = 8
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    private func updateCollectionViewLayout() {
        let newLayout = createCollectionViewLayout()
        collectionView.setCollectionViewLayout(newLayout, animated: true)
    }
    
    private func showEmptyState() {
        let emptyLabel = UILabel()
        emptyLabel.text = "No comics in your library\nTap + to import comics"
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.font = .systemFont(ofSize: 18)
        emptyLabel.numberOfLines = 0
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc private func importButtonTapped() {
        comicImporter.importComics(presentingViewController: self)
    }
    
    private func sortComics(by sortType: ComicSortType) {
        switch sortType {
        case .title:
            comics.sort { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        case .dateAdded:
            comics.sort { $0.dateAdded > $1.dateAdded }
        }
        
        comicStorage.saveComics(comics)
        collectionView.reloadData()
    }
    
    private func confirmClearLibrary() {
        let alert = UIAlertController(
            title: "Clear Library",
            message: "This will remove all comics from your library. This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { _ in
            self.comics.removeAll()
            self.comicStorage.saveComics([])
            self.collectionView.reloadData()
            self.showEmptyState()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func loadComics() {
        comics = comicStorage.loadComics()
        collectionView.reloadData()
        
        if comics.isEmpty {
            showEmptyState()
        }
    }
    
    private func saveComics() {
        comicStorage.saveComics(comics)
    }
    
    private func openComicReader(for comic: ComicBook, at index: Int) {
        let readerVC = ComicReaderViewController()
        readerVC.comic = comic
        readerVC.delegate = self
        readerVC.modalPresentationStyle = .fullScreen
        present(readerVC, animated: true)
    }
}

// MARK: - UICollectionViewDataSource
extension LibraryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return comics.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ComicCell", for: indexPath) as! ComicCell
        let comic = comics[indexPath.item]
        cell.configure(with: comic)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension LibraryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let comic = comics[indexPath.item]
        openComicReader(for: comic, at: indexPath.item)
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let comic = comics[indexPath.item]
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let readAction = UIAction(title: "Read", image: UIImage(systemName: "book.open")) { _ in
                self.openComicReader(for: comic, at: indexPath.item)
            }
            
            let infoAction = UIAction(title: "Info", image: UIImage(systemName: "info.circle")) { _ in
                self.showComicInfo(comic)
            }
            
            let deleteAction = UIAction(title: "Remove", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self.removeComic(at: indexPath.item)
            }
            
            return UIMenu(title: comic.title, children: [readAction, infoAction, deleteAction])
        }
    }
    
    private func showComicInfo(_ comic: ComicBook) {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        
        let message = """
        Pages: \(comic.totalPages)
        Size: \(formatter.string(fromByteCount: comic.fileSize))
        Added: \(DateFormatter.localizedString(from: comic.dateAdded, dateStyle: .medium, timeStyle: .none))
        Progress: \(comic.currentPageIndex + 1) / \(comic.totalPages)
        """
        
        let alert = UIAlertController(title: comic.title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func removeComic(at index: Int) {
        comics.remove(at: index)
        saveComics()
        collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
        
        if comics.isEmpty {
            showEmptyState()
        }
    }
}

// MARK: - ComicImporterDelegate
extension LibraryViewController: ComicImporterDelegate {
    func didImportComics(_ newComics: [ComicBook]) {
        let startIndex = comics.count
        comics.append(contentsOf: newComics)
        saveComics()
        
        // Remove empty state if present
        view.subviews.filter { $0 is UILabel }.forEach { $0.removeFromSuperview() }
        
        // Insert new items
        let indexPaths = (startIndex..<comics.count).map { IndexPath(item: $0, section: 0) }
        collectionView.insertItems(at: indexPaths)
    }
    
    func didFailToImport(error: Error) {
        let alert = UIAlertController(title: "Import Failed", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - ComicReaderDelegate
extension LibraryViewController: ComicReaderDelegate {
    func didUpdateReadingProgress(for comic: ComicBook, currentPage: Int) {
        if let index = comics.firstIndex(where: { $0.id == comic.id }) {
            comics[index].currentPageIndex = currentPage
            saveComics()
            
            // Update the visible cell if needed
            let indexPath = IndexPath(item: index, section: 0)
            if let cell = collectionView.cellForItem(at: indexPath) as? ComicCell {
                cell.configure(with: comics[index])
            }
        }
    }
}

// MARK: - LibrarySettingsDelegate
extension LibraryViewController: LibrarySettingsDelegate {
    func didUpdateLibrarySettings(_ settings: LibrarySettings) {
        // Force update the layout with new settings
        DispatchQueue.main.async {
            self.updateCollectionViewLayout()
        }
    }
}

enum ComicSortType {
    case title
    case dateAdded
}

protocol ComicReaderDelegate: AnyObject {
    func didUpdateReadingProgress(for comic: ComicBook, currentPage: Int)
}
