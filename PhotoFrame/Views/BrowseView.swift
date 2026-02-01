import SwiftUI

struct BrowseView: View {
    @ObservedObject var photoManager = PhotoManager.shared
    
    let columns = [
        GridItem(.adaptive(minimum: 100))
    ]
    
    @State private var showSettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(Array(photoManager.photos.enumerated()), id: \.element) { index, url in
                        NavigationLink(destination: PhotoDetailView(selectedIndex: index)) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipped()
                                    .cornerRadius(8)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 100, height: 100)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Photos")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gear")
                            .font(.title2)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SlideshowView()) {
                        Text("Play Slideshow")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onAppear {
                photoManager.loadPhotos()
            }
        }
        .navigationViewStyle(.stack)
    }
}
