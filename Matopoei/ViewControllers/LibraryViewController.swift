import UIKit

class LibraryViewController: UIViewController {

    private var collectionView: UICollectionView!
    private var comics: [ComicBook] = []
    private let comicImporter = ComicImporter()
    private let comicStorage = ComicStorage()
    private var currentFolder: ComicFolder? // Add this property
    
    // Add this initializer to support folder filtering
    init(folder: ComicFolder? = nil) {
        self.currentFolder = folder
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.currentFolder = nil
        super.init(coder: coder)
    }

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
        loadComics() // Reload to get fresh data
        collectionView.reloadData()
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
        // Update title based on folder or main library
        if let folder = currentFolder {
            title = folder.name
        } else {
            title = "Library"
        }
        
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemBackground
        comicImporter.delegate = self
        
        // Add import button (only show in main library, not in folders)
        if currentFolder == nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "plus"),
                style: .plain,
                target: self,
                action: #selector(importButtonTapped)
            )
        }

        // Add settings button with menu
        let settingsMenu = createSettingsMenu()
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            primaryAction: nil,
            menu: settingsMenu
        )
    }
    
    private func createSettingsMenu() -> UIMenu {
        var actions: [UIAction] = []
        
        // Sort options
        actions.append(UIAction(title: "Sort by Title", image: UIImage(systemName: "textformat.abc")) { _ in
            self.sortComics(by: .title)
        })
        
        actions.append(UIAction(title: "Sort by Date Added", image: UIImage(systemName: "calendar")) { _ in
            self.sortComics(by: .dateAdded)
        })
        
        // If in a folder, add "Move All to Library" option
        if currentFolder != nil {
            actions.append(UIAction(title: "Move All to Library", image: UIImage(systemName: "arrow.up.bin")) { _ in
                self.moveAllComicsToLibrary()
            })
        } else {
            // If in main library, add "Clear Library" option
            actions.append(UIAction(title: "Clear Library", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self.confirmClearLibrary()
            })
        }
        
        return UIMenu(title: "", children: actions)
    }

    private func createCollectionViewLayout() -> UICollectionViewLayout {
        let isLandscape = view.bounds.width > view.bounds.height
        let columnsCount = isLandscape ? 4 : 3
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0 / CGFloat(columnsCount)),
            heightDimension: .absolute(320)
        )

        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(320)
        )

        // Fix: Use iOS version compatibility
        let group: NSCollectionLayoutGroup
        if #available(iOS 16.0, *) {
            group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                repeatingSubitem: item,
                count: columnsCount
            )
        } else {
            // iOS 15 and earlier fallback
            group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitem: item,
                count: columnsCount
            )
        }

        group.interItemSpacing = .fixed(8)
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 16, bottom: 20, trailing: 16)
        section.interGroupSpacing = 8
        return UICollectionViewCompositionalLayout(section: section)
    }

    private func showEmptyState() {
        let message = currentFolder != nil ?
            "No comics in this folder\nMove comics here from the main library" :
            "No comics in your library\nTap + to import comics"
            
        let emptyLabel = UILabel()
        emptyLabel.text = message
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
        
        collectionView.reloadData()
    }
    
    private func moveAllComicsToLibrary() {
        guard let folder = currentFolder else { return }
        
        let alert = UIAlertController(
            title: "Move All Comics",
            message: "Move all comics from '\(folder.name)' back to the main library?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Move", style: .default) { _ in
            // Remove comics from folder
            var updatedFolder = folder
            updatedFolder.comicIds.removeAll()
            
            // Update folders in storage
            var folders = self.comicStorage.loadFolders()
            if let folderIndex = folders.firstIndex(where: { $0.id == folder.id }) {
                folders[folderIndex] = updatedFolder
                self.comicStorage.saveFolders(folders)
            }
            
            // Refresh view
            self.loadComics()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
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
        // Remove any existing empty state
        view.subviews.filter { $0 is UILabel }.forEach { $0.removeFromSuperview() }
        
        let allComics = comicStorage.loadComics()
        
        if let folder = currentFolder {
            // Filter comics for this specific folder
            comics = allComics.filter { comic in
                folder.comicIds.contains(comic.id)
            }
        } else {
            // Show all comics (main library)
            comics = allComics
        }
        
        collectionView.reloadData()
        
        if comics.isEmpty {
            showEmptyState()
        }
    }

    private func saveComics() {
        comicStorage.saveComics(comics)
    }

    private func openComicReader(for comic: ComicBook, at index: Int) {
        // Update lastReadDate
        var updatedComic = comic
        updatedComic.lastReadDate = Date()
        
        // Save updated comic
        var allComics = comicStorage.loadComics()
        if let comicIndex = allComics.firstIndex(where: { $0.id == comic.id }) {
            allComics[comicIndex] = updatedComic
            comicStorage.saveComics(allComics)
        }
        
        let readerVC = ComicReaderViewController()
        readerVC.comic = updatedComic
        readerVC.delegate = self
        readerVC.modalPresentationStyle = .fullScreen
        present(readerVC, animated: true)
    }

    // Rest of your existing methods remain the same...
    
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
        let comic = comics[index]
        comics.remove(at: index)
        
        // Remove from storage
        var allComics = comicStorage.loadComics()
        allComics.removeAll { $0.id == comic.id }
        comicStorage.saveComics(allComics)
        
        // Remove from any folders
        var folders = comicStorage.loadFolders()
        for i in folders.indices {
            folders[i].comicIds.removeAll { $0 == comic.id }
        }
        comicStorage.saveFolders(folders)
        
        collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
        
        if comics.isEmpty {
            showEmptyState()
        }
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
            var actions: [UIAction] = []
            
            actions.append(UIAction(title: "Read", image: UIImage(systemName: "book.open")) { _ in
                self.openComicReader(for: comic, at: indexPath.item)
            })
            
            actions.append(UIAction(title: "Info", image: UIImage(systemName: "info.circle")) { _ in
                self.showComicInfo(comic)
            })
            
            // Add folder management options
            if self.currentFolder == nil {
                actions.append(UIAction(title: "Add to Folder", image: UIImage(systemName: "folder.badge.plus")) { _ in
                    self.showAddToFolderMenu(for: comic)
                })
            }
            
            actions.append(UIAction(title: "Remove", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self.removeComic(at: indexPath.item)
            })
            
            return UIMenu(title: comic.title, children: actions)
        }
    }
    
    private func showAddToFolderMenu(for comic: ComicBook) {
        let folders = comicStorage.loadFolders()
        
        if folders.isEmpty {
            let alert = UIAlertController(title: "No Folders", message: "Create a folder first from the sidebar", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let alert = UIAlertController(title: "Add to Folder", message: "Choose a folder for '\(comic.title)'", preferredStyle: .actionSheet)
        
        for folder in folders {
            alert.addAction(UIAlertAction(title: folder.name, style: .default) { _ in
                self.addComicToFolder(comic, folder: folder)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = collectionView
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        
        present(alert, animated: true)
    }
    
    private func addComicToFolder(_ comic: ComicBook, folder: ComicFolder) {
        var updatedFolder = folder
        updatedFolder.addComic(comic.id)
        
        var folders = comicStorage.loadFolders()
        if let folderIndex = folders.firstIndex(where: { $0.id == folder.id }) {
            folders[folderIndex] = updatedFolder
            comicStorage.saveFolders(folders)
            
            // Show success message
            let alert = UIAlertController(title: "Added", message: "'\(comic.title)' added to '\(folder.name)'", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
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
        // Update the comic's reading progress
        var updatedComic = comic
        updatedComic.currentPageIndex = currentPage
        updatedComic.lastReadDate = Date()
        
        // Update in storage
        var allComics = comicStorage.loadComics()
        if let index = allComics.firstIndex(where: { $0.id == comic.id }) {
            allComics[index] = updatedComic
            comicStorage.saveComics(allComics)
        }
        
        // Update local comics array if needed
        if let localIndex = comics.firstIndex(where: { $0.id == comic.id }) {
            comics[localIndex] = updatedComic
        }
    }
}
