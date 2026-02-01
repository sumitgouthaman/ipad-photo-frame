import SwiftUI

struct ContentView: View {
    @ObservedObject var appLockManager = AppLockManager.shared
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        Group {
            if appLockManager.isAppLockEnabled && !appLockManager.isUnlocked {
                LockedView(authenticateAction: {
                    appLockManager.authenticate()
                })
            } else {
                BrowseView()
            }
        }
        .onAppear {
            if appLockManager.isAppLockEnabled {
                appLockManager.authenticate()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                appLockManager.lock()
            }
        }
    }
}
