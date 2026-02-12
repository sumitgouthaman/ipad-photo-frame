import SwiftUI

struct SlideshowView: View {
    @ObservedObject var photoManager = PhotoManager.shared
    @State private var currentIndex = 0
    @State private var timer: Timer?
    @State private var showControls = false
    
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
        .onTapGesture {
            withAnimation {
                showControls.toggle()
            }
        }
    }
    
    func startSlideshow() {
        showControls = false // Ensure hidden on start
        if photoManager.photos.isEmpty { return }
        if isRandom {
            currentIndex = Int.random(in: 0..<photoManager.photos.count)
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
    
    func advanceSlide() {
        if photoManager.photos.isEmpty { return }
        
        if isRandom {
            var newIndex = Int.random(in: 0..<photoManager.photos.count)
            if photoManager.photos.count > 1 && newIndex == currentIndex {
                newIndex = (newIndex + 1) % photoManager.photos.count
            }
            currentIndex = newIndex
        } else {
            currentIndex = (currentIndex + 1) % photoManager.photos.count
        }
        
        // Schedule next advance (resets timer)
        stopSlideshow()
        scheduleNextAdvance()
    }
    
    func previousSlide() {
        if photoManager.photos.isEmpty { return }
        
        if isRandom {
            // Random doesn't have a deterministic "previous", so just pick another random
            advanceSlide()
        } else {
            currentIndex = (currentIndex - 1 + photoManager.photos.count) % photoManager.photos.count
        }
        
        stopSlideshow()
        scheduleNextAdvance()
    }
}
