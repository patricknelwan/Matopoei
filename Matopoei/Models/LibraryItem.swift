import Foundation

enum LibraryItem {
    case comic(ComicBook)
    case folder(FileBrowserItem, comicCount: Int)
    
    var title: String {
        switch self {
        case .comic(let comic):
            return comic.title
        case .folder(let folder, _):
            return folder.name
        }
    }
}
