import Foundation
import Combine


class PhotoManager: ObservableObject {
    static let shared = PhotoManager()
    
    @Published var photos: [URL] = []
    
    private let fileManager = FileManager.default
    
    /// Photos are stored in Application Support/Photos, excluded from iCloud sync and backups
    var photosDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("Photos", isDirectory: true)
    }
    
    init() {
        setupPhotosDirectory()
        loadPhotos()
    }
    
    private func setupPhotosDirectory() {
        var directory = photosDirectory
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: directory.path) {
            do {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            } catch {
                print("Error creating photos directory: \(error)")
                return
            }
        }
        
        // Exclude from iCloud backup
        do {
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try directory.setResourceValues(resourceValues)
            print("Photos directory excluded from backup: \(directory.path)")
        } catch {
            print("Error excluding photos directory from backup: \(error)")
        }
    }
    
    func loadPhotos() {
        do {
            let files = try fileManager.contentsOfDirectory(at: photosDirectory, includingPropertiesForKeys: nil)
            let imageExtensions = ["jpg", "jpeg", "png", "heic", "gif", "webp"]
            photos = files.filter { url in
                imageExtensions.contains(url.pathExtension.lowercased())
            }.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
            print("Loaded \(photos.count) photos")
        } catch {
            print("Error loading photos: \(error)")
            photos = []
        }
    }
    
    private var reloadWorkItem: DispatchWorkItem?
    
    func savePhoto(data: Data, filename: String) {
        let uniqueName = "\(UUID().uuidString)_\(filename)"
        let fileURL = photosDirectory.appendingPathComponent(uniqueName)
        do {
            try data.write(to: fileURL)
            print("Saved photo to \(fileURL.path)")
            // Debounce reload
            scheduleReload()
        } catch {
            print("Error saving photo: \(error)")
        }
    }
    
    func deletePhoto(at url: URL) {
        do {
            try fileManager.removeItem(at: url)
            scheduleReload()
        } catch {
            print("Error deleting photo: \(error)")
        }
    }
    
    private func scheduleReload() {
        reloadWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.loadPhotos()
        }
        reloadWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: item)
    }
    
    func deleteAllPhotos() {
        for photo in photos {
            do {
                try fileManager.removeItem(at: photo)
            } catch {
                print("Error deleting photo: \(error)")
            }
        }
        scheduleReload()
    }
}
