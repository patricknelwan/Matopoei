import UIKit

class LibraryViewController: UIViewController {

    private var collectionView: UICollectionView!
    private var comics: [ComicBook] = []
    private let comicImporter = ComicImporter()
    private let comicStorage = ComicStorage()
    private var currentFolderURL: URL? // Updated to track folder URL instead of ComicFolder

    // Updated initializer to accept folder URL
    init(folderURL: URL? = nil) {
        self.currentFolderURL = folderURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.currentFolderURL = nil
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupUI()
        loadComics()
        
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
        loadComics()
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
        if let folderURL = currentFolderURL {
            title = folderURL.lastPathComponent
        } else {
            title = "All Comics"
        }

        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemBackground
        comicImporter.delegate = self
        
        // Add import button (only show in main library, not in folders)
        if currentFolderURL == nil {
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

        // If in a folder, add "Move All to Main Library" option
        if currentFolderURL != nil {
            actions.append(UIAction(title: "Move All to Main Library", image: UIImage(systemName: "arrow.up.bin")) { _ in
                self.moveAllComicsToMainLibrary()
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

    // Updated loadComics to work purely with file system
    private func loadComics() {
        // Remove any existing empty state
        view.subviews.filter { $0 is UILabel }.forEach { $0.removeFromSuperview() }
        
        let fileManager = FileManager.default
        
        do {
            if let folderURL = currentFolderURL {
                // Load comics from specific folder
                title = folderURL.lastPathComponent
                let contents = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
                let comicURLs = contents.filter { url in
                    let pathExtension = url.pathExtension.lowercased()
                    return ["cbz", "cbr", "zip"].contains(pathExtension)
                }
                
                // Load saved metadata for comics that exist in the file system
                let savedComics = comicStorage.loadComics()
                
                comics = comicURLs.compactMap { comicURL in
                    // First try to find existing comic metadata
                    if let existingComic = savedComics.first(where: { $0.fileURL == comicURL }) {
                        return existingComic
                    } else {
                        // Create comic on-the-fly for files without metadata
                        let pageCount = ArchiveProcessor.getPageCount(from: comicURL)
                        guard pageCount > 0 else { return nil }
                        
                        let coverImage = ArchiveProcessor.extractCoverImage(from: comicURL)
                        let coverImageData = coverImage?.jpegData(compressionQuality: 0.8)
                        
                        let comic = ComicBook(
                            title: comicURL.deletingPathExtension().lastPathComponent,
                            fileURL: comicURL,
                            coverImageData: coverImageData,
                            totalPages: pageCount
                        )
                        
                        // Save this new comic to storage
                        var updatedSavedComics = comicStorage.loadComics()
                        updatedSavedComics.append(comic)
                        comicStorage.saveComics(updatedSavedComics)
                        
                        return comic
                    }
                }
                
            } else {
                // Load all comics from entire Documents directory
                title = "All Comics"
                guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    comics = []
                    return
                }
                
                // Find all comic files in file system
                let foundComicURLs = findAllComicURLs(in: documentsURL)
                let savedComics = comicStorage.loadComics()
                
                comics = foundComicURLs.compactMap { comicURL in
                    // First try to find existing comic metadata
                    if let existingComic = savedComics.first(where: { $0.fileURL == comicURL }) {
                        return existingComic
                    } else {
                        // Create comic on-the-fly for files without metadata
                        let pageCount = ArchiveProcessor.getPageCount(from: comicURL)
                        guard pageCount > 0 else { return nil }
                        
                        let coverImage = ArchiveProcessor.extractCoverImage(from: comicURL)
                        let coverImageData = coverImage?.jpegData(compressionQuality: 0.8)
                        
                        let comic = ComicBook(
                            title: comicURL.deletingPathExtension().lastPathComponent,
                            fileURL: comicURL,
                            coverImageData: coverImageData,
                            totalPages: pageCount
                        )
                        
                        // Save this new comic to storage
                        var updatedSavedComics = comicStorage.loadComics()
                        updatedSavedComics.append(comic)
                        comicStorage.saveComics(updatedSavedComics)
                        
                        return comic
                    }
                }
                
                // Clean up storage - remove metadata for files that no longer exist
                cleanupOrphanedComics(existingURLs: foundComicURLs)
            }
            
            collectionView.reloadData()
            if comics.isEmpty {
                showEmptyState()
            }
            
        } catch {
            print("Error loading folder contents: \(error)")
            comics = []
            collectionView.reloadData()
            showEmptyState()
        }
    }

    // Helper method to find all comic file URLs
    private func findAllComicURLs(in directory: URL) -> [URL] {
        let fileManager = FileManager.default
        var allComicURLs: [URL] = []
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            
            for url in contents {
                var isDirectory: ObjCBool = false
                fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
                
                if isDirectory.boolValue {
                    // Recursively search subdirectories
                    allComicURLs.append(contentsOf: findAllComicURLs(in: url))
                } else {
                    // Check if it's a comic file
                    let pathExtension = url.pathExtension.lowercased()
                    if ["cbz", "cbr", "zip"].contains(pathExtension) {
                        allComicURLs.append(url)
                    }
                }
            }
        } catch {
            print("Error searching directory \(directory.path): \(error)")
        }
        
        return allComicURLs
    }

    // Clean up orphaned comic metadata for files that no longer exist
    private func cleanupOrphanedComics(existingURLs: [URL]) {
        let savedComics = comicStorage.loadComics()
        let cleanedComics = savedComics.filter { comic in
            existingURLs.contains(comic.fileURL)
        }
        
        // Only save if we actually removed some comics
        if cleanedComics.count != savedComics.count {
            comicStorage.saveComics(cleanedComics)
            print("Cleaned up \(savedComics.count - cleanedComics.count) orphaned comic entries")
        }
    }

    private func showEmptyState() {
        let message = currentFolderURL != nil ?
            "No comics in this folder\nMove comics here or import new ones" :
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

    private func moveAllComicsToMainLibrary() {
        guard let folderURL = currentFolderURL else { return }
        
        let alert = UIAlertController(
            title: "Move All Comics",
            message: "Move all comics from '\(folderURL.lastPathComponent)' to the main library?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Move", style: .default) { _ in
            self.performMoveAllComicsToMainLibrary()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func performMoveAllComicsToMainLibrary() {
        guard let folderURL = currentFolderURL else { return }
        
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            
            for fileURL in contents {
                let destinationURL = documentsURL.appendingPathComponent(fileURL.lastPathComponent)
                
                // Handle name conflicts
                var finalDestinationURL = destinationURL
                var counter = 1
                while fileManager.fileExists(atPath: finalDestinationURL.path) {
                    let nameWithoutExtension = destinationURL.deletingPathExtension().lastPathComponent
                    let fileExtension = destinationURL.pathExtension
                    let newName = "\(nameWithoutExtension)_\(counter).\(fileExtension)"
                    finalDestinationURL = documentsURL.appendingPathComponent(newName)
                    counter += 1
                }
                
                try fileManager.moveItem(at: fileURL, to: finalDestinationURL)
            }
            
            // Refresh view
            loadComics()
            
        } catch {
            print("Error moving comics: \(error)")
            showError("Failed to move comics: \(error.localizedDescription)")
        }
    }

    private func confirmClearLibrary() {
        let alert = UIAlertController(
            title: "Clear Library",
            message: "This will remove all comics from your library. This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { _ in
            self.performClearLibrary()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func performClearLibrary() {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        do {
            // Delete all comic files recursively
            let allComicURLs = findAllComicURLs(in: documentsURL)
            for comicURL in allComicURLs {
                try fileManager.removeItem(at: comicURL)
            }
            
            // Clear storage
            comicStorage.saveComics([])
            comicStorage.clearAll() // This also clears cover images
            
            // Update UI
            comics.removeAll()
            collectionView.reloadData()
            showEmptyState()
            
            print("✅ Library cleared: deleted \(allComicURLs.count) comic files")
            
        } catch {
            print("❌ Error clearing library: \(error)")
            showError("Failed to clear library: \(error.localizedDescription)")
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
        
        let alert = UIAlertController(title: "Remove Comic", message: "Are you sure you want to delete '\(comic.title)'?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            // Delete the actual file
            do {
                try FileManager.default.removeItem(at: comic.fileURL)
                
                // Remove from comics array
                self.comics.remove(at: index)
                
                // Remove from storage
                var allComics = self.comicStorage.loadComics()
                allComics.removeAll { $0.id == comic.id }
                self.comicStorage.saveComics(allComics)
                
                // Update UI
                self.collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
                
                if self.comics.isEmpty {
                    self.showEmptyState()
                }
            } catch {
                print("Error deleting comic: \(error)")
                self.showError("Failed to delete comic: \(error.localizedDescription)")
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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
            
            // Add folder management options only in main library
            if self.currentFolderURL == nil {
                actions.append(UIAction(title: "Move to Folder", image: UIImage(systemName: "folder.badge.plus")) { _ in
                    self.showMoveToFolderMenu(for: comic, at: indexPath.item)
                })
            }
            
            actions.append(UIAction(title: "Remove", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self.removeComic(at: indexPath.item)
            })
            
            return UIMenu(title: comic.title, children: actions)
        }
    }
    
    private func showMoveToFolderMenu(for comic: ComicBook, at index: Int) {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            let folders = contents.filter { url in
                var isDirectory: ObjCBool = false
                fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
                return isDirectory.boolValue
            }.sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            
            if folders.isEmpty {
                let alert = UIAlertController(title: "No Folders", message: "Create a folder first from the sidebar", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                return
            }
            
            let alert = UIAlertController(title: "Move to Folder", message: "Choose a folder for '\(comic.title)'", preferredStyle: .actionSheet)
            
            for folderURL in folders {
                alert.addAction(UIAlertAction(title: folderURL.lastPathComponent, style: .default) { _ in
                    self.moveComicToFolder(comic, at: index, folderURL: folderURL)
                })
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            if let popover = alert.popoverPresentationController {
                popover.sourceView = collectionView
                popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            }
            
            present(alert, animated: true)
        } catch {
            print("Error loading folders: \(error)")
        }
    }
    
    private func moveComicToFolder(_ comic: ComicBook, at index: Int, folderURL: URL) {
        let fileManager = FileManager.default
        let destinationURL = folderURL.appendingPathComponent(comic.fileURL.lastPathComponent)
        
        do {
            // Handle name conflicts
            var finalDestinationURL = destinationURL
            var counter = 1
            while fileManager.fileExists(atPath: finalDestinationURL.path) {
                let nameWithoutExtension = destinationURL.deletingPathExtension().lastPathComponent
                let fileExtension = destinationURL.pathExtension
                let newName = "\(nameWithoutExtension)_\(counter).\(fileExtension)"
                finalDestinationURL = folderURL.appendingPathComponent(newName)
                counter += 1
            }
            
            try fileManager.moveItem(at: comic.fileURL, to: finalDestinationURL)
            
            // Remove from current view
            comics.remove(at: index)
            collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
            
            if comics.isEmpty {
                showEmptyState()
            }
            
            // Show success message
            let alert = UIAlertController(title: "Moved", message: "'\(comic.title)' moved to '\(folderURL.lastPathComponent)'", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            
        } catch {
            print("Error moving comic: \(error)")
            showError("Failed to move comic: \(error.localizedDescription)")
        }
    }
}

// MARK: - ComicImporterDelegate
extension LibraryViewController: ComicImporterDelegate {
    func didImportComics(_ newComics: [ComicBook]) {
        // Refresh to show newly imported comics
        loadComics()
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
