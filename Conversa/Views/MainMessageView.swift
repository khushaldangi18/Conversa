import SwiftUI

struct MainMessageView: View {
    @State private var showingNewChat = false
    
    var body: some View{
        NavigationView{
            VStack{
                HStack{
                    Text("Conversa").bold()
                        .font(.system(size: 30))
                }.padding(.horizontal)
                ScrollView{
                    ForEach(0..<10, id: \.self){ num in
                        VStack{
                            HStack(spacing: 16){
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 35))
                                    .foregroundColor(.gray)
                                VStack(alignment: .leading){
                                    Text("Username").bold()
                                    Text("Message sent to user").foregroundColor(.gray)
                                }
                                Spacer()
                                Text("1d")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            Divider()
                        }.padding(EdgeInsets(top: 2, leading: 10, bottom: 2, trailing:10))
                    }
                }
            }
            .overlay(
                Button {
                    showingNewChat = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 34))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.green)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                        .padding()
                }
                .padding()
                , alignment: .bottomTrailing
            )
        }
        .sheet(isPresented: $showingNewChat) {
            NewChatView()
        }
    }
}
#Preview {
    MainMessageView()
}
