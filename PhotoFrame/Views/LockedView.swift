import SwiftUI

struct LockedView: View {
    var authenticateAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Photo Frame is Locked")
                .font(.title)
                .fontWeight(.bold)
            
            Button(action: authenticateAction) {
                Text("Unlock")
                    .font(.headline)
                    .padding()
                    .frame(width: 200)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}
