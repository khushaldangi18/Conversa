import SwiftUI

struct AuthView: View {
    @State private var isLogin = false
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 20) {
            Text(isLogin ? "Login" : "Create Account")
                .font(.system(size: 28, weight: .bold))

            HStack(spacing: 0) {
                Button(action: {
                    isLogin = true
                }) {
                    Text("Login")
                        .foregroundColor(isLogin ? .black : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(isLogin ? Color.white : Color(.systemGray5))
                        .cornerRadius(8)
                }

                Button(action: {
                    isLogin = false
                }) {
                    Text("Create Account")
                        .foregroundColor(!isLogin ? .black : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(!isLogin ? Color.white : Color(.systemGray5))
                        .cornerRadius(8)
                }
            }
            .background(Color(.systemGray5))
            .clipShape(Capsule())
            .padding(.horizontal)

            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
                .padding(.top, 20)

            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .autocapitalization(.none)

                SecureField("Password", text: $password)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            Button(action: {
                // Add auth logic here
            }) {
                Text(isLogin ? "Login" : "Create Account")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.top, 10)

            Spacer()
        }
        .padding(.top, 40)
        .background(Color(.systemGray6))
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
    }
}
