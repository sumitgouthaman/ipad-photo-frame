import SwiftUI

struct ContentView: View {
    @ObservedObject var appLockManager = AppLockManager.shared
    @Environment(\.scenePhase) var scenePhase
    @State private var showPrivacyOverlay = false
    
    var body: some View {
        ZStack {
            Group {
                if appLockManager.isAppLockEnabled && !appLockManager.isUnlocked {
                    LockedView(authenticateAction: {
                        appLockManager.authenticate()
                    })
                } else {
                    BrowseView()
                }
            }
            
            // Privacy overlay for app switcher
            if showPrivacyOverlay && appLockManager.isAppLockEnabled {
                PrivacyOverlayView()
            }
        }
        .onAppear {
            if appLockManager.isAppLockEnabled {
                appLockManager.authenticate()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .inactive:
                // Show privacy overlay immediately when going to app switcher
                showPrivacyOverlay = true
            case .background:
                appLockManager.lock()
            case .active:
                // Hide overlay when returning to app
                showPrivacyOverlay = false
            @unknown default:
                break
            }
        }
    }
}

/// Privacy overlay shown in app switcher to hide sensitive content
struct PrivacyOverlayView: View {
    var body: some View {
        ZStack {
            // Blur effect background
            Color(.systemBackground)
                .opacity(0.95)
            
            VStack(spacing: 16) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                Text("Photo Frame")
                    .font(.title2)
                    .fontWeight(.medium)
            }
        }
        .ignoresSafeArea()
    }
}
