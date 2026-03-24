import SwiftUI

struct SlideshowView: View {
    @ObservedObject var photoManager = PhotoManager.shared
    @State private var currentIndex = 0
    @State private var timer: Timer?
    @State private var showControls = false

    /// History stack for "back" navigation in random mode
    @State private var history: [Int] = []

    @AppStorage("slideshowDuration") private var duration: Double = 5.0
    @AppStorage("slideshowRandom") private var isRandom: Bool = false

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)

                if !photoManager.photos.isEmpty {
                    if photoManager.photos[currentIndex].pathExtension.lowercased() == "gif" {
                         GIFView(url: photoManager.photos[currentIndex])
                             .scaledToFit()
                             .frame(width: geometry.size.width, height: geometry.size.height)
                             .id(currentIndex)
                    } else {
                        AsyncImage(url: photoManager.photos[currentIndex]) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .transition(.opacity)
                                .id(currentIndex)
                        } placeholder: {
                            ProgressView()
                        }
                    }
                } else {
                    Text("No photos available")
                        .foregroundColor(.white)
                }

                // Overlay Controls
                if showControls {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                stopSlideshow()
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                    .padding()
                            }
                            .padding(.top, 20)
                            .padding(.trailing, 20)
                        }

                        Spacer()

                        // Manual Navigation Controls
                        HStack {
                            Button(action: { previousSlide() }) {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding()

                            Spacer()

                            Button(action: { advanceSlide() }) {
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
                        withAnimation { advanceSlide() }
                    } else if value.translation.width > 50 {
                        // Swipe Right -> Previous
                        withAnimation { previousSlide() }
                    }
                }
        )
        .onTapGesture {
            withAnimation {
                showControls.toggle()
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true // Prevent sleep
            startSlideshow()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false // Allow sleep again
            stopSlideshow()
        }
    }

    func startSlideshow() {
        showControls = false // Ensure hidden on start
        if photoManager.photos.isEmpty { return }
        history = [currentIndex]
        if isRandom {
            let newIndex = pickRandomIndex(excluding: currentIndex)
            history = [newIndex]
            currentIndex = newIndex
        }
        scheduleNextAdvance()
    }

    /// Schedules the next slide advance using a one-shot timer.
    /// For GIFs, waits at least one full loop duration before advancing.
    func scheduleNextAdvance() {
        let currentURL = photoManager.photos[currentIndex]
        var interval = duration // default slideshow duration

        if currentURL.pathExtension.lowercased() == "gif",
           let gifLen = gifDuration(for: currentURL) {
            // Use the longer of: one full GIF loop or the slideshow duration
            interval = max(gifLen, duration)
        }

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 1.0)) {
                advanceSlide()
            }
        }
    }

    func stopSlideshow() {
        timer?.invalidate()
        timer = nil
    }

    /// Returns a random index that avoids repeating the given index (when possible).
    private func pickRandomIndex(excluding current: Int) -> Int {
        guard photoManager.photos.count > 1 else { return current }
        var newIndex = Int.random(in: 0..<photoManager.photos.count)
        while newIndex == current {
            newIndex = Int.random(in: 0..<photoManager.photos.count)
        }
        return newIndex
    }

    func advanceSlide() {
        if photoManager.photos.isEmpty { return }

        let newIndex: Int
        if isRandom {
            newIndex = pickRandomIndex(excluding: currentIndex)
        } else {
            newIndex = (currentIndex + 1) % photoManager.photos.count
        }

        history.append(newIndex)
        currentIndex = newIndex

        // Schedule next advance (resets timer)
        stopSlideshow()
        scheduleNextAdvance()
    }

    func previousSlide() {
        if photoManager.photos.isEmpty { return }

        // Pop the current entry from history to go back
        if history.count > 1 {
            history.removeLast()
            currentIndex = history.last!
        } else if !isRandom {
            // Sequential mode: wrap backwards
            let newIndex = (currentIndex - 1 + photoManager.photos.count) % photoManager.photos.count
            history = [newIndex]
            currentIndex = newIndex
        }
        // In random mode with no history left, stay on the current image.

        stopSlideshow()
        scheduleNextAdvance()
    }
}
