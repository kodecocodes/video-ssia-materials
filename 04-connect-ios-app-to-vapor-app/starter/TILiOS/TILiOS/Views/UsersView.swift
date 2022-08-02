/// Copyright (c) 2022 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import SwiftUI

struct UsersView: View {
  @State private var showingSheet = false
  @State private var users: [User] = []
  @State private var showingUserErrorAlert = false
  @EnvironmentObject var auth: Auth
  let usersRequest: ResourceRequest<User>
  let apiHostname: String
  
  init(apiHostname: String) {
    self.usersRequest = ResourceRequest<User>(apiHostname: apiHostname, resourcePath: "users")
    self.apiHostname = apiHostname
  }

  var body: some View {
    NavigationView {
      List(users, id: \.id) { user in
        VStack(alignment: .leading) {
          Text(user.name)
            .font(.title2)
          Text(user.username)
            .font(.caption)
        }
      }
      .navigationTitle("Users")
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button(
            action: {
              auth.logout()
            }, label: {
              Text("Log Out")
            })
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(
            action: {
              showingSheet.toggle()
            }, label: {
              Image(systemName: "plus")
            })
        }
      }
    }
    .sheet(isPresented: $showingSheet) {
      CreateUserView(apiHostname: self.apiHostname)
        .onDisappear {
          Task {
            await loadData()
          }
        }
    }
    .task {
      await loadData()
    }
    .alert(isPresented: $showingUserErrorAlert) {
      Alert(title: Text("Error"), message: Text("There was an error getting the users"))
    }
  }

  @MainActor
  func loadData() async {
    do {
      self.users = try await usersRequest.getAll()
    } catch {
      self.showingUserErrorAlert = true
    }
  }
}

struct UsersView_Previews: PreviewProvider {
  static var previews: some View {
    UsersView(apiHostname: AppMain.apiHostname)
  }
}
