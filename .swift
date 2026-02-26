import SwiftUI

struct LoginView: View {
    
    @Binding var isLoggedIn: Bool
    @Environment(\.dismiss) var dismiss
    
    @State private var username = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 24) {
            
            Text("Login to Continue")
                .font(.title2)
                .fontWeight(.bold)
            
            TextField("Username", text: $username)
                .textFieldStyle(.roundedBorder)
            
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
            
            Button("Login") {
                if !username.isEmpty && !password.isEmpty {
                    isLoggedIn = true
                    dismiss()
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
    }
}
