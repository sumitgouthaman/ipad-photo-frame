import SwiftUI

struct PhotoDetailView: View {
    @ObservedObject var photoManager = PhotoManager.shared
    @State var selectedIndex: Int
    @State private var showControls = false
    
    var body: some View {
        TabView(selection: $selectedIndex) {
            ForEach(0..<photoManager.photos.count, id: \.self) { index in
                GeometryReader { geometry in
                    ZStack {
                        Color.black.edgesIgnoringSafeArea(.all)
                        
                        AsyncImage(url: photoManager.photos[index]) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        } placeholder: {
                            ProgressView()
                        }
                    }
                }
                .tag(index)
                .ignoresSafeArea()
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if showControls {
                    // Standard Back button handles exit, but we can add extra controls if needed
                }
            }
        }
        // Toggle controls on tap
        .onTapGesture {
            withAnimation {
                showControls.toggle()
            }
        }
        // Force hide/show bars based on state
        .statusBar(hidden: !showControls)
        .toolbar(showControls ? .visible : .hidden, for: .navigationBar)
        .toolbar(showControls ? .visible : .hidden, for: .tabBar) // Requires iOS 16+
    }
}
