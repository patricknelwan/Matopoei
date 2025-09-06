import UIKit

enum SidebarSection: Int, CaseIterable {
    case main = 0
    case folders = 1
    
    var title: String {
        switch self {
        case .main: return "Main"
        case .folders: return "Folders"
        }
    }
}

enum MainMenuItem: Int, CaseIterable {
    case readingNow = 0
    case library = 1
    case importComics = 2
    
    var title: String {
        switch self {
        case .readingNow: return "Reading Now"
        case .library: return "All Comics"
        case .importComics: return "Import Comics"
        }
    }
    
    var icon: String {
        switch self {
        case .readingNow: return "book.fill"
        case .library: return "books.vertical.fill"
        case .importComics: return "plus.circle.fill"
        }
    }
}

class SidebarViewController: UIViewController {
    
    private var tableView: UITableView!
    private let comicStorage = ComicStorage()
    private var folders: [FileBrowserItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadDirectories()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadDirectories()
        tableView.reloadData()
    }
    
    private func setupUI() {
        title = "Matopoei"
        view.backgroundColor = .systemBackground
        
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SidebarCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FolderCell")
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "folder.badge.plus"),
            style: .plain,
            target: self,
            action: #selector(createNewFolder)
        )
    }
    
    private func loadDirectories() {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            
            // Filter only directories
            folders = contents.compactMap { url in
                let item = FileBrowserItem(url: url)
                return item.isDirectory ? item : nil
            }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            
        } catch {
            print("Error loading directories: \(error)")
            folders = []
        }
    }
    
    @objc private func createNewFolder() {
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
            loadDirectories()
            tableView.reloadData()
        } catch {
            print("❌ Failed to create folder: \(error)")
            showError("Failed to create folder: \(error.localizedDescription)")
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showLibrary(folderURL: URL? = nil) {
        let libraryVC = LibraryViewController(folderURL: folderURL)
        presentDetailViewController(libraryVC)
    }
    
    private func showReadingNow() {
        let readingNowVC = ReadingNowViewController()
        presentDetailViewController(readingNowVC)
    }
    
    private func showImport() {
        let importVC = ComicImportViewController()
        presentDetailViewController(importVC)
    }
    
    private func presentDetailViewController(_ viewController: UIViewController) {
        let navController = UINavigationController(rootViewController: viewController)
        splitViewController?.setViewController(navController, for: .secondary)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension SidebarViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return SidebarSection.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sidebarSection = SidebarSection(rawValue: section) else { return 0 }
        
        switch sidebarSection {
        case .main:
            return MainMenuItem.allCases.count
        case .folders:
            return folders.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sidebarSection = SidebarSection(rawValue: section) else { return nil }
        return sidebarSection.title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sidebarSection = SidebarSection(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        
        switch sidebarSection {
        case .main:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SidebarCell", for: indexPath)
            let menuItem = MainMenuItem.allCases[indexPath.row]
            
            var configuration = cell.defaultContentConfiguration()
            configuration.text = menuItem.title
            configuration.image = UIImage(systemName: menuItem.icon)
            cell.contentConfiguration = configuration
            
            return cell
            
        case .folders:
            let cell = tableView.dequeueReusableCell(withIdentifier: "FolderCell", for: indexPath)
            let folder = folders[indexPath.row]
            
            var configuration = cell.defaultContentConfiguration()
            configuration.text = folder.name
            configuration.image = UIImage(systemName: "folder.fill")
            
            // Count comics in folder
            let comicCount = countComicsInFolder(folder.url)
            configuration.secondaryText = "\(comicCount) comics"
            
            cell.contentConfiguration = configuration
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let sidebarSection = SidebarSection(rawValue: indexPath.section) else { return }
        
        switch sidebarSection {
        case .main:
            let menuItem = MainMenuItem.allCases[indexPath.row]
            switch menuItem {
            case .readingNow:
                showReadingNow()
            case .library:
                showLibrary() // All comics
            case .importComics:
                showImport()
            }
            
        case .folders:
            let folder = folders[indexPath.row]
            showLibrary(folderURL: folder.url) // Comics in specific folder
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete,
              let sidebarSection = SidebarSection(rawValue: indexPath.section),
              sidebarSection == .folders else { return }
        
        let folder = folders[indexPath.row]
        
        let alert = UIAlertController(
            title: "Delete Folder",
            message: "Are you sure you want to delete '\(folder.name)'? All comics will be moved to the main library.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.deleteFolder(folder)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func deleteFolder(_ folder: FileBrowserItem) {
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
            
            loadDirectories()
            tableView.reloadData()
            
        } catch {
            showError("Failed to delete folder: \(error.localizedDescription)")
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
}
