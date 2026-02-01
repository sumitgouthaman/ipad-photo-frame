import Foundation
import Foundation
import UIKit
import Combine


class PhotoManager: ObservableObject {
    static let shared = PhotoManager()
    
    @Published var photos: [URL] = []
    
    private let fileManager = FileManager.default
    
    var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    init() {
        loadPhotos()
    }
    
    func loadPhotos() {
        do {
            let files = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            let imageExtensions = ["jpg", "jpeg", "png", "heic"]
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
        let fileURL = documentsDirectory.appendingPathComponent(uniqueName)
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
            deletePhoto(at: photo)
        }
    }
}
