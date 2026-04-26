import SwiftUI

struct PhotoDetailView: View {
    @ObservedObject var photoManager = PhotoManager.shared
    @State var selectedIndex: Int
    @State private var showControls = false

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)

                if !photoManager.photos.isEmpty && selectedIndex < photoManager.photos.count {
                    let url = photoManager.photos[selectedIndex]
                    if url.pathExtension.lowercased() == "gif" {
                        GIFView(url: url)
                            .scaledToFit()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .id(selectedIndex)
                    } else {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .transition(.opacity)
                                .id(selectedIndex)
                        } placeholder: {
                            ProgressView()
                        }
                    }
                }

                // Overlay Controls (same style as SlideshowView)
                if showControls {
                    VStack {
                        HStack {
                            // Back button (left side of top bar)
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                    .padding()
                            }
                            .padding(.top, 20)
                            .padding(.leading, 20)

                            Spacer()
                        }

                        Spacer()

                        // Previous / Next arrows
                        HStack {
                            Button(action: { previousPhoto() }) {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding()

                            Spacer()

                            Button(action: { nextPhoto() }) {
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding()
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .navigationBarHidden(true)
        .statusBar(hidden: !showControls)
        .background(Color.black)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -50 {
                        // Swipe Left -> Next
                        withAnimation { nextPhoto() }
                    } else if value.translation.width > 50 {
                        // Swipe Right -> Previous
                        withAnimation { previousPhoto() }
                    }
                }
        )
        .onTapGesture {
            withAnimation {
                showControls.toggle()
            }
        }
    }

    private func nextPhoto() {
        guard !photoManager.photos.isEmpty else { return }
        selectedIndex = (selectedIndex + 1) % photoManager.photos.count
    }

    private func previousPhoto() {
        guard !photoManager.photos.isEmpty else { return }
        selectedIndex = (selectedIndex - 1 + photoManager.photos.count) % photoManager.photos.count
    }
}
