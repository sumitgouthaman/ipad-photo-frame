import SwiftUI

struct SettingsView: View {
    @ObservedObject var webServer = WebServerManager.shared
    @ObservedObject var photoManager = PhotoManager.shared
    
    @Environment(\.presentationMode) var presentationMode
    
    @AppStorage("slideshowDuration") private var duration: Double = 5.0
    @AppStorage("slideshowRandom") private var isRandom: Bool = false
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Web Server")) {
                    Toggle("Enable Web Server", isOn: Binding(
                        get: { webServer.isRunning },
                        set: { if $0 { webServer.start() } else { webServer.stop() } }
                    ))
                    
                    if webServer.isRunning {
                        VStack(alignment: .leading) {
                            Text("Connect to upload:")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(webServer.serverURL)
                                .font(.headline)
                                .foregroundColor(.blue)
                                .contextMenu {
                                    Button("Copy") {
                                        #if canImport(UIKit)
                                        UIPasteboard.general.string = webServer.serverURL
                                        #endif
                                    }
                                }
                        }
                    }
                }
                
                Section(header: Text("Slideshow Settings")) {
                    Toggle("Random Order", isOn: $isRandom)
                    
                    VStack(alignment: .leading) {
                        Text("Duration: \(Int(duration)) seconds")
                        Slider(value: $duration, in: 2...60, step: 1)
                    }
                }
                
                Section(header: Text("Storage")) {
                    Text("Total Photos: \(photoManager.photos.count)")
                    
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Text("Delete All Photos")
                            .foregroundColor(.red)
                    }
                    .alert(isPresented: $showDeleteConfirmation) {
                        Alert(
                            title: Text("Delete All Photos"),
                            message: Text("Are you sure you want to delete all photos? This cannot be undone."),
                            primaryButton: .destructive(Text("Delete")) {
                                photoManager.deleteAllPhotos()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
            }

            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .navigationViewStyle(.stack)
    }
}
