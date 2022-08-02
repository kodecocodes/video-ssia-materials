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

struct CreateAcronymView: View {
  @State var short = ""
  @State var long = ""
  @Environment(\.presentationMode) var presentationMode
  @EnvironmentObject var auth: Auth
  @State private var showingAcronymSaveErrorAlert = false
  let apiHostname: String

  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("Acronym").textCase(.uppercase)) {
          TextField("Acronym", text: $short)
            .autocapitalization(.allCharacters)
            .disableAutocorrection(true)
        }
        Section(header: Text("Meaning").textCase(.uppercase)) {
          TextField("Meaning", text: $long)
            .autocapitalization(.words)
        }
      }
      .navigationBarTitle("Create Acronym", displayMode: .inline)
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
          AsyncButton(action: saveAcronym) {
            Text("Save")
          }
          .disabled(short.isEmpty || long.isEmpty)
      )
    }
    .alert(isPresented: $showingAcronymSaveErrorAlert) {
      Alert(title: Text("Error"), message: Text("There was a problem saving the acronym"))
    }
  }

  @MainActor
  func saveAcronym() async {
    let acronymSaveData = CreateAcronymData(short: short, long: long)
    do {
      _ = try await ResourceRequest<Acronym>(apiHostname: self.apiHostname, resourcePath: "acronyms").save(acronymSaveData, auth: auth)
      presentationMode.wrappedValue.dismiss()
    } catch {
      self.showingAcronymSaveErrorAlert = true
    }
  }
}

struct CreateAcronymView_Previews: PreviewProvider {
  static var previews: some View {
    CreateAcronymView(apiHostname: AppMain.apiHostname)
  }
}
