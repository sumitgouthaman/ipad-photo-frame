import Foundation
import LocalAuthentication
import SwiftUI
import Combine

class AppLockManager: ObservableObject {
    static let shared = AppLockManager()
    
    @AppStorage("isAppLockEnabled") var isAppLockEnabled: Bool = false
    @Published var isUnlocked: Bool = false
    
    func authenticate() {
        // If lock is disabled, we are always "unlocked"
        if !isAppLockEnabled {
            isUnlocked = true
            return
        }
        
        let context = LAContext()
        var error: NSError?
        
        // check if biometric authentication is possible
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Unlock to access your photos"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isUnlocked = true
                    } else {
                        // Failed to authenticate
                        self.isUnlocked = false
                        print("Authentication failed")
                    }
                }
            }
        } else {
            // No biometrics available
            // In a real app, fall back to passcode or allow access if secure hardware is missing
            print("Biometrics not available")
            // For safety, if enabled but no hardware, keep locked or handle gracefully.
            // Here we might just unlock or show error.
            self.isUnlocked = false
        }
    }
    
    func lock() {
        if isAppLockEnabled {
            isUnlocked = false
        } else {
            isUnlocked = true
        }
    }
}
