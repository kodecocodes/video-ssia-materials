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

struct CreateUserView: View {
  @State var name = ""
  @State var username = ""
  @State var password = ""
  @Environment(\.presentationMode) var presentationMode
  @EnvironmentObject var auth: Auth
  @State private var showingUserSaveErrorAlert = false
  let apiHostname: String

  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("Name").textCase(.uppercase)) {
          TextField("Name", text: $name)
        }
        Section(header: Text("Username").textCase(.uppercase)) {
          TextField("Username", text: $username)
            .autocapitalization(.none)
            .keyboardType(.emailAddress)
        }
        Section(header: Text("Password").textCase(.uppercase)) {
          SecureField("Password", text: $password)
        }
      }
      .navigationBarTitle("Create User", displayMode: .inline)
      .navigationBarItems(
        leading:
          Button(
            action: {
              presentationMode.wrappedValue.dismiss()
            }, label: {
              Text("Cancel")
                .fontWeight(Font.Weight.regular)
            }),
        trailing:
          AsyncButton(action: saveUser) {
            Text("Save")
          }
          .disabled(name.isEmpty || username.isEmpty || password.isEmpty)
      )
    }
    .alert(isPresented: $showingUserSaveErrorAlert) {
      Alert(title: Text("Error"), message: Text("There was a problem saving the user"))
    }
  }

  @MainActor
  func saveUser() async {
    let userData = CreateUserData(name: name, username: username, password: password)
    do {
      _ = try await ResourceRequest<User>(apiHostname: self.apiHostname, resourcePath: "users").save(userData, auth: auth)
      presentationMode.wrappedValue.dismiss()
    } catch {
      self.showingUserSaveErrorAlert = true
    }
  }
}

struct CreateUserView_Previews: PreviewProvider {
  static var previews: some View {
    CreateUserView(apiHostname: AppMain.apiHostname)
  }
}
