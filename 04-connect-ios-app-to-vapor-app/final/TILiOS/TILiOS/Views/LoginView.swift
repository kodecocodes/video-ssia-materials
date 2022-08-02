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
import AuthenticationServices

struct LoginView: View {
  let apiHostname: String
  @State var username = ""
  @State var password = ""
  @State private var showingLoginErrorAlert = false
  @EnvironmentObject var auth: Auth
  
  var body: some View {
    VStack {
      Image("logo")
        .aspectRatio(contentMode: .fit)
        .padding(.leading, 75)
        .padding(.trailing, 75)
      Text("Log In")
        .font(.largeTitle)
      TextField("Username", text: $username)
        .padding()
        .autocapitalization(.none)
        .keyboardType(.emailAddress)
        .border(Color("rw-dark"), width: 1)
        .padding(.horizontal)
      SecureField("Password", text: $password)
        .padding()
        .border(Color("rw-dark"), width: 1)
        .padding(.horizontal)
      AsyncButton("Log In") {
        if let token = await login() {
          auth.token = token
        }
      }
      .frame(width: 120.0, height: 60.0)
      .disabled(username.isEmpty || password.isEmpty)
      SignInWithAppleButton(.signIn) { request in
        request.requestedScopes = [.fullName, .email]
      } onCompletion: { result in
        Task {
          let apiToken = try await handleSIWA(result: result)
          auth.token = apiToken.value
        }
      }
      .padding()
      .frame(width: 250, height: 70)
    }
    .alert(isPresented: $showingLoginErrorAlert) {
      Alert(title: Text("Error"), message: Text("Could not log in. Check your credentials and try again"))
    }
  }
  
  @MainActor
  func login() async -> String? {
    do {
      let token = try await auth.login(username: username, password: password)
      return token
    } catch {
      self.showingLoginErrorAlert = true
      return nil
    }
  }
  
  @MainActor
  func handleSIWA(result: Result<ASAuthorization, Error>) async throws -> Token {
    switch result {
    case .failure(let error):
      self.showingLoginErrorAlert = true
      print("Error: \(error)")
      throw error
    case .success(let authResult):
      if let credential = authResult.credential as? ASAuthorizationAppleIDCredential {
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
          print("Failed to get token from credential")
          self.showingLoginErrorAlert = true
          throw AuthError.badResponse
        }
        let name: String?
        if let nameProvided = credential.fullName {
          name = "\(nameProvided.givenName ?? "") \(nameProvided.familyName ?? "")"
        } else {
          name = nil
        }
        let requestData = SignInWithAppleToken(token: tokenString, name: name, username: credential.email)
        let path = "\(apiHostname)/auth/siwa"
        guard let url = URL(string: path) else {
          fatalError("Failed to convert URL")
        }
        do {
          var loginRequest = URLRequest(url: url)
          loginRequest.httpMethod = "POST"
          loginRequest.httpBody = try JSONEncoder().encode(requestData)
          
          let (data, response) = try await URLSession.shared.data(for: loginRequest)
          guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            self.showingLoginErrorAlert = true
            throw AuthError.badResponse
          }
          return try JSONDecoder().decode(Token.self, from: data)
        } catch {
          self.showingLoginErrorAlert = true
          throw error
        }
      } else {
        self.showingLoginErrorAlert = true
        throw AuthError.badResponse
      }
    }
  }
}

struct Login_Previews: PreviewProvider {
  static var previews: some View {
    LoginView(apiHostname: AppMain.apiHostname)
  }
}
