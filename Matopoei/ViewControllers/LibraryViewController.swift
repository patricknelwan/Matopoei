import UIKit

class LibraryViewController: UIViewController {
    
    private var collectionView: UICollectionView!
    private var libraryItems: [LibraryItem] = []
    private let comicImporter = ComicImporter()
    private let comicStorage = ComicStorage()
    private var currentFolderURL: URL?
    
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
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
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
        
        // Register both cell types
        collectionView.register(ComicCell.self, forCellWithReuseIdentifier: "ComicCell")
        collectionView.register(FolderCell.self, forCellWithReuseIdentifier: "FolderCell")
        
        view.addSubview(collectionView)
    }
    
    private func setupUI() {
        if let folderURL = currentFolderURL {
            title = folderURL.lastPathComponent
            
            let parentURL = folderURL.deletingLastPathComponent()
            let previousFolderName = parentURL.lastPathComponent == "" ? "Library" : parentURL.lastPathComponent
            
            let backButton = UIBarButtonItem(
                title: "\(previousFolderName)",
                style: .plain,
                target: self,
                action: #selector(backButtonTapped)
            )
            
            navigationItem.leftBarButtonItem = backButton
            
        } else {
            title = "All Comics"
            
            // Add settings menu for main library
            let settingsMenu = createSettingsMenu()
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "gear"),
                primaryAction: nil,
                menu: settingsMenu
            )
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
    }
    
    private func createSettingsMenu() -> UIMenu {
        var actions: [UIAction] = []
        
        // Sort options
        actions.append(UIAction(title: "Sort by Title", image: UIImage(systemName: "textformat.abc")) { _ in
            self.sortLibraryItems(by: .title)
        })
        
        actions.append(UIAction(title: "Sort by Date Added", image: UIImage(systemName: "calendar")) { _ in
            self.sortLibraryItems(by: .dateAdded)
        })
        
        // Show Hidden Folders Toggle
        let showHiddenFolders = UserDefaults.standard.bool(forKey: "showHiddenFolders")
        let hiddenFoldersTitle = showHiddenFolders ? "Hide System Folders" : "Show System Folders"
        let hiddenFoldersIcon = showHiddenFolders ? "eye.slash" : "eye"
        
        actions.append(UIAction(title: hiddenFoldersTitle, image: UIImage(systemName: hiddenFoldersIcon)) { _ in
            self.toggleHiddenFolders()
        })
                
        // If in a folder, add "Move All to Main Library" option
        if currentFolderURL != nil {
            actions.append(UIAction(title: "Move All to Main Library", image: UIImage(systemName: "arrow.up.bin")) { _ in
                self.moveAllComicsToMainLibrary()
            })
        } else {
            // If in main library, add "Create Folder" and "Clear Library" options
            actions.append(UIAction(title: "Create Folder", image: UIImage(systemName: "folder.badge.plus")) { _ in
                self.showCreateFolderDialog()
            })
            
            actions.append(UIAction(title: "Clear Library", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self.confirmClearLibrary()
            })
        }
        
        return UIMenu(title: "", children: actions)
    }
    
    private func toggleHiddenFolders() {
        let currentSetting = UserDefaults.standard.bool(forKey: "showHiddenFolders")
        let newSetting = !currentSetting
        
        UserDefaults.standard.set(newSetting, forKey: "showHiddenFolders")
        
        // Verify it was saved
        let savedSetting = UserDefaults.standard.bool(forKey: "showHiddenFolders")
        
        // Reload the library to reflect the change
        loadComics()
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
                // Load comics from specific folder (no folders shown here)
                title = folderURL.lastPathComponent
                let contents = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
                let comicURLs = contents.filter { url in
                    let pathExtension = url.pathExtension.lowercased()
                    return ["cbz", "cbr", "zip"].contains(pathExtension)
                }
                
                let savedComics = comicStorage.loadComics()
                let comics = comicURLs.compactMap { comicURL in
                    if let existingComic = savedComics.first(where: { $0.fileURL == comicURL }) {
                        return existingComic
                    } else {
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
                        
                        var updatedSavedComics = comicStorage.loadComics()
                        updatedSavedComics.append(comic)
                        comicStorage.saveComics(updatedSavedComics)
                        
                        return comic
                    }
                }
                
                // Convert to LibraryItems (only comics in folder view)
                libraryItems = comics.map { .comic($0) }
                
            } else {
                // Load from main Documents directory - show both folders and comics
                title = "All Comics"
                guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    libraryItems = []
                    return
                }
                
                let contents = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
                
                var items: [LibraryItem] = []
                
                // Add folders first - conditionally filter hidden folders based on setting
                let showHiddenFolders = UserDefaults.standard.bool(forKey: "showHiddenFolders")

                let allFolders = contents.filter { url in
                    var isDirectory: ObjCBool = false
                    fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
                    return isDirectory.boolValue
                }

                let folders = contents.filter { url in
                    var isDirectory: ObjCBool = false
                    fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
                    
                    let folderName = url.lastPathComponent.lowercased()
                    let isSystemFolder = folderName.starts(with: ".") // .Trash, .DS_Store, etc.
                    
                    print("🔍 Checking folder: \(folderName), isSystemFolder: \(isSystemFolder), showHidden: \(showHiddenFolders)")
                    
                    // Show all folders if setting is enabled, otherwise hide system folders
                    if showHiddenFolders {
                        return isDirectory.boolValue
                    } else {
                        return isDirectory.boolValue && !isSystemFolder
                    }
                }.sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
                
                for folderURL in folders {
                    let folderItem = FileBrowserItem(url: folderURL)
                    let comicCount = countComicsInFolder(folderURL)
                    items.append(.folder(folderItem, comicCount: comicCount))
                }
                
                // Add comics in root directory
                let comicURLs = contents.filter { url in
                    let pathExtension = url.pathExtension.lowercased()
                    return ["cbz", "cbr", "zip"].contains(pathExtension)
                }.sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
                
                let savedComics = comicStorage.loadComics()
                let comics = comicURLs.compactMap { comicURL in
                    if let existingComic = savedComics.first(where: { $0.fileURL == comicURL }) {
                        return existingComic
                    } else {
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
                        
                        var updatedSavedComics = comicStorage.loadComics()
                        updatedSavedComics.append(comic)
                        comicStorage.saveComics(updatedSavedComics)
                        
                        return comic
                    }
                }
                
                // Add comics to items
                items.append(contentsOf: comics.map { .comic($0) })
                
                libraryItems = items
                
                // Clean up orphaned comics
                let foundComicURLs = findAllComicURLs(in: documentsURL)
                cleanupOrphanedComics(existingURLs: foundComicURLs)
            }
            
            collectionView.reloadData()
            if libraryItems.isEmpty {
                showEmptyState()
            }
            
        } catch {
            print("Error loading folder contents: \(error)")
            libraryItems = []
            collectionView.reloadData()
            showEmptyState()
        }
    }
    
    private func countComicsInFolder(_ folderURL: URL) -> Int {
        let fileManager = FileManager.default
        do {
            let contents = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            return contents.filter { url in
                let pathExtension = url.pathExtension.lowercased()
                return ["cbz", "cbr", "zip"].contains(pathExtension)
            }.count
        } catch {
            return 0
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
    
    private func sortLibraryItems(by sortType: ComicSortType) {
        libraryItems.sort { item1, item2 in
            switch (item1, item2) {
            case (.comic(let comic1), .comic(let comic2)):
                switch sortType {
                case .title:
                    return comic1.title.localizedStandardCompare(comic2.title) == .orderedAscending
                case .dateAdded:
                    return comic1.dateAdded > comic2.dateAdded
                }
            case (.folder(let folder1, _), .folder(let folder2, _)):
                return folder1.name.localizedStandardCompare(folder2.name) == .orderedAscending
            case (.folder, .comic):
                return true // Folders first
            case (.comic, .folder):
                return false // Folders first
            }
        }
        
        collectionView.reloadData()
    }
    
    private func showCreateFolderDialog() {
        let alert = UIAlertController(title: "New Folder", message: "Enter folder name", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Folder name"
            textField.autocapitalizationType = .words
        }
        
        alert.addAction(UIAlertAction(title: "Create", style: .default) { _ in
            guard let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty else { return }
            
            self.createPhysicalFolder(named: name)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func createPhysicalFolder(named folderName: String) {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let folderURL = documentsURL.appendingPathComponent(folderName)
        
        do {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            print("✅ Created folder: \(folderURL.path)")
            loadComics() // Refresh the view
        } catch {
            print("❌ Failed to create folder: \(error)")
            showError("Failed to create folder: \(error.localizedDescription)")
        }
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
            message: "This will remove all comics and folders from your library. This action cannot be undone.",
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
            // Delete all files and folders recursively
            let contents = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            for item in contents {
                try fileManager.removeItem(at: item)
            }
            
            // Clear storage
            comicStorage.saveComics([])
            comicStorage.clearAll() // This also clears cover images
            
            // Update UI
            libraryItems.removeAll()
            collectionView.reloadData()
            showEmptyState()
            
            print("✅ Library cleared: deleted all files and folders")
            
        } catch {
            print("❌ Error clearing library: \(error)")
            showError("Failed to clear library: \(error.localizedDescription)")
        }
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
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDataSource
extension LibraryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return libraryItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = libraryItems[indexPath.item]
        
        switch item {
        case .comic(let comic):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ComicCell", for: indexPath) as! ComicCell
            cell.configure(with: comic)
            return cell
            
        case .folder(let folder, let comicCount):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FolderCell", for: indexPath) as! FolderCell
            cell.configure(with: folder, comicCount: comicCount)
            return cell
        }
    }
}

// MARK: - UICollectionViewDelegate
extension LibraryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let item = libraryItems[indexPath.item]
        
        switch item {
        case .comic(let comic):
            openComicReader(for: comic, at: indexPath.item)
            
        case .folder(let folder, _):
            // Navigate to folder
            let folderLibraryVC = LibraryViewController(folderURL: folder.url)
            navigationController?.pushViewController(folderLibraryVC, animated: true)
        }
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let item = libraryItems[indexPath.item]
        
        switch item {
        case .comic(let comic):
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
                    self.removeItem(at: indexPath.item)
                })
                
                return UIMenu(title: comic.title, children: actions)
            }
            
        case .folder(let folder, let comicCount):
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                var actions: [UIAction] = []
                
                actions.append(UIAction(title: "Open", image: UIImage(systemName: "folder.badge.gearshape")) { _ in
                    let folderLibraryVC = LibraryViewController(folderURL: folder.url)
                    self.navigationController?.pushViewController(folderLibraryVC, animated: true)
                })
                
                actions.append(UIAction(title: "Rename", image: UIImage(systemName: "pencil")) { _ in
                    self.renameFolder(folder)
                })
                
                actions.append(UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                    self.deleteFolder(folder)
                })
                
                return UIMenu(title: folder.name, children: actions)
            }
        }
    }
    
    private func removeItem(at index: Int) {
        let item = libraryItems[index]
        
        switch item {
        case .comic(let comic):
            let alert = UIAlertController(title: "Remove Comic", message: "Are you sure you want to delete '\(comic.title)'?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                do {
                    try FileManager.default.removeItem(at: comic.fileURL)
                    
                    // Remove from items array
                    self.libraryItems.remove(at: index)
                    
                    // Remove from storage
                    var allComics = self.comicStorage.loadComics()
                    allComics.removeAll { $0.id == comic.id }
                    self.comicStorage.saveComics(allComics)
                    
                    // Update UI
                    self.collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
                    if self.libraryItems.isEmpty {
                        self.showEmptyState()
                    }
                    
                } catch {
                    print("Error deleting comic: \(error)")
                    self.showError("Failed to delete comic: \(error.localizedDescription)")
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
            
        case .folder(let folder, _):
            deleteFolder(folder)
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
                let alert = UIAlertController(title: "No Folders", message: "Create a folder from the settings menu", preferredStyle: .alert)
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
            libraryItems.remove(at: index)
            collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
            
            if libraryItems.isEmpty {
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
    
    private func renameFolder(_ folder: FileBrowserItem) {
        let alert = UIAlertController(title: "Rename Folder", message: "Enter new name", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = folder.name
            textField.placeholder = "Folder name"
        }
        
        alert.addAction(UIAlertAction(title: "Rename", style: .default) { _ in
            guard let newName = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !newName.isEmpty,
                  newName != folder.name else { return }
            
            let fileManager = FileManager.default
            let newURL = folder.url.deletingLastPathComponent().appendingPathComponent(newName)
            
            do {
                try fileManager.moveItem(at: folder.url, to: newURL)
                self.loadComics() // Refresh the view
            } catch {
                self.showError("Failed to rename folder: \(error.localizedDescription)")
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func deleteFolder(_ folder: FileBrowserItem) {
        let alert = UIAlertController(
            title: "Delete Folder",
            message: "Are you sure you want to delete '\(folder.name)'? All comics will be moved to the main library.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            let fileManager = FileManager.default
            guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return
            }
            
            do {
                // Move all files from folder to Documents root
                let folderContents = try fileManager.contentsOfDirectory(at: folder.url, includingPropertiesForKeys: nil)
                for fileURL in folderContents {
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
                
                // Delete the empty folder
                try fileManager.removeItem(at: folder.url)
                self.loadComics() // Refresh the view
                
            } catch {
                self.showError("Failed to delete folder: \(error.localizedDescription)")
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
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
        
        // Update local library items if needed
        if let localIndex = libraryItems.firstIndex(where: { item in
            if case .comic(let localComic) = item {
                return localComic.id == comic.id
            }
            return false
        }) {
            libraryItems[localIndex] = .comic(updatedComic)
        }
    }
}
