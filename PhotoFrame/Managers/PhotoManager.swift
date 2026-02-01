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
    
    func savePhoto(data: Data, filename: String) {
        let uniqueName = "\(UUID().uuidString)_\(filename)"
        let fileURL = documentsDirectory.appendingPathComponent(uniqueName)
        do {
            try data.write(to: fileURL)
            print("Saved photo to \(fileURL.path)")
            // Reload on main thread
            DispatchQueue.main.async {
                self.loadPhotos()
            }
        } catch {
            print("Error saving photo: \(error)")
        }
    }
    
    func deletePhoto(at url: URL) {
        do {
            try fileManager.removeItem(at: url)
            DispatchQueue.main.async {
                self.loadPhotos()
            }
        } catch {
            print("Error deleting photo: \(error)")
        }
    }
    
    func deleteAllPhotos() {
        for photo in photos {
            deletePhoto(at: photo)
        }
    }
}
