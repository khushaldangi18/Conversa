////
////  ProfileView.swift
////  Conversa
////
////  Created by FCP27 on 11/07/25.
////
//
//import SwiftUI
//
//
//struct ChatUser{
//    let uid, email, profileImageUrl: String
//}
//
//class ProfileViewModel: ObservableObject {
//    @Published var ChatUser: ChatUser?
//    init(){
//        fetchCurrentUser()
//    }
//    
//    private func fetchCurrentUser(){
//        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
//        
//        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument{
//            snapshot, error in
//            if let error = error {
//                print("Failed to fetch current user")
//                return
//            }
//            guard let data = snapshot?.data() else {return}
////            print(data)
//            
//            let uid = data["uid"] as? String ?? ""
//            let email = data["email"] as? String ?? ""
//            let profileImgeUrl = data["profileImgeUrl"] as? String ?? ""
//            self.ChatUser = ChatUser(uid: uid, email: email, profileImageUrl: profileImgeUrl)
//        }
//    }
//}
//
//struct ProfileView: View {
////    @State private var username = "\"
//    @State private var email = "Email"
//    @State private var showingSignOutAlert = false
//    @ObservedObject private var vm = ProfileViewModel()
//    
//    var body: some View {
//        NavigationView {
//            ScrollView {
//                VStack(spacing: 20) {
//                    // Profile Header
//                    VStack(spacing: 15) {
//                        Image(systemName: "person.circle.fill")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 120, height: 120)
//                            .foregroundColor(.blue)
//                            .padding(.top, 20)
//                        
//                        Text(\(vm.ChatUser?.email ?? "")")
//                            .font(.system(size: 24, weight: .bold))
//                        
//                        Text(email)
//                            .font(.subheadline)
//                            .foregroundColor(.gray)
//                        
//                    }
//                    .padding()
//                    
//                    // Stats Section
////                    HStack(spacing: 40) {
////                        VStack {
////                            Text("128")
////                                .font(.title2)
////                                .fontWeight(.bold)
////                            Text("Messages")
////                                .font(.caption)
////                                .foregroundColor(.gray)
////                        }
////                        
////                        VStack {
////                            Text("24")
////                                .font(.title2)
////                                .fontWeight(.bold)
////                            Text("Contacts")
////                                .font(.caption)
////                                .foregroundColor(.gray)
////                        }
////                        
////                        VStack {
////                            Text("5")
////                                .font(.title2)
////                                .fontWeight(.bold)
////                            Text("Groups")
////                                .font(.caption)
////                                .foregroundColor(.gray)
////                        }
////                    }
////                    .padding()
////                    .background(Color(.systemGray6))
////                    .cornerRadius(12)
////                    .padding(.horizontal)
////                    
////                    // Settings Section
////                    VStack(spacing: 0) {
////                        ProfileSettingRow(icon: "bell", title: "Notifications", color: .orange)
////                        ProfileSettingRow(icon: "lock", title: "Privacy", color: .blue)
////                        ProfileSettingRow(icon: "person.2", title: "Account", color: .green)
////                        ProfileSettingRow(icon: "questionmark.circle", title: "Help", color: .purple)
////                    }
////                    .background(Color(.systemBackground))
////                    .cornerRadius(12)
////                    .padding(.horizontal)
////                    
////                    // Sign Out Button
////                    Button(action: {
////                        showingSignOutAlert = true
////                    }) {
////                        HStack {
////                            Image(systemName: "rectangle.portrait.and.arrow.right")
////                            Text("Sign Out")
////                        }
////                        .foregroundColor(.white)
////                        .frame(maxWidth: .infinity)
////                        .padding()
////                        .background(Color.red)
////                        .cornerRadius(12)
////                        .padding(.horizontal)
////                    }
////                    .padding(.top, 10)
//                    .alert(isPresented: $showingSignOutAlert) {
//                        Alert(
//                            title: Text("Sign Out"),
//                            message: Text("Are you sure you want to sign out?"),
//                            primaryButton: .destructive(Text("Sign Out")) {
//                                // Sign out action here
//                            },
//                            secondaryButton: .cancel()
//                        )
//                    }
////                    
//                    Spacer()
//                }
//            }
//            .navigationTitle("Profile")
//            .navigationBarTitleDisplayMode(.inline)
//        }
//    }
//}
//
//struct ProfileSettingRow: View {
//    let icon: String
//    let title: String
//    let color: Color
//    
//    var body: some View {
//        HStack {
//            Image(systemName: icon)
//                .foregroundColor(color)
//                .frame(width: 30)
//            
//            Text(title)
//                .foregroundColor(.primary)
//            
//            Spacer()
//            
//            Image(systemName: "chevron.right")
//                .foregroundColor(.gray)
//                .font(.system(size: 14))
//        }
//        .padding()
//        .background(Color(.systemBackground))
//        
//        Divider()
//            .padding(.leading, 50)
//    }
//}
//
//#Preview {
//    ProfileView()
//}
