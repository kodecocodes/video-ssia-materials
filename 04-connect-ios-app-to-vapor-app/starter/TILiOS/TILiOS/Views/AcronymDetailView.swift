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

struct AcronymDetailView: View {
  var acronym: Acronym
  let apiHostname: String
  @State private var user: User?
  @State private var categories: [Category] = []
  @State private var short = ""
  @State private var long = ""
  @State private var showingSheet = false
  @State private var isShowingAddToCategoryView = false
  @State private var showingUserErrorAlert = false
  @State private var showingCategoriesErrorAlert = false
  @Environment(\.presentationMode) var presentationMode

  var body: some View {
    Form {
      Section(header: Text("Acronym").textCase(.uppercase)) {
        Text(acronym.short)
      }
      Section(header: Text("Meaning").textCase(.uppercase)) {
        Text(acronym.long)
      }
      if let user = user {
        Section(header: Text("User").textCase(.uppercase)) {
          Text(user.name)
        }
      }
      if !categories.isEmpty {
        Section(header: Text("Categories").textCase(.uppercase)) {
          List(categories, id: \.id) { category in
            Text(category.name)
          }
        }
      }
      Section {
        Button("Add To Category") {
          isShowingAddToCategoryView = true
        }
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      Button(
        action: {
          showingSheet.toggle()
        }, label: {
          Text("Edit")
        })
    }
    .sheet(isPresented: $showingSheet) {
      EditAcronymView(acronym: acronym, apiHostname: self.apiHostname)
    }
    NavigationLink(destination: AddToCategoryView(acronym: acronym, apiHostname: self.apiHostname, selectedCategories: self.categories), isActive: $isShowingAddToCategoryView) {
      EmptyView()
    }
    .task {
      await getAcronymData()
    }
    .alert(isPresented: $showingUserErrorAlert) {
      Alert(title: Text("Error"), message: Text("There was an error getting the acronym's user"))
    }
    .alert(isPresented: $showingCategoriesErrorAlert) {
      Alert(title: Text("Error"), message: Text("There was an error getting the acronym's categories"))
    }
  }

  @MainActor
  func getAcronymData() async {
    guard let id = acronym.id else {
      return
    }
    let acronymDetailRequester = AcronymRequest(acronymID: id, apiHostname: self.apiHostname)
    
    async let user = acronymDetailRequester.getUser()
    async let categories = acronymDetailRequester.getCategories()
    
    do {
      self.user = try await user
    } catch {
      self.showingUserErrorAlert = true
    }
    
    do {
      self.categories = try await categories
    } catch {
      self.showingCategoriesErrorAlert = true
    }
  }
}

struct AcronymDetailView_Previews: PreviewProvider {
  static var previews: some View {
    let acronym = Acronym(short: "OMG", long: "Oh My God", userID: UUID())
    AcronymDetailView(acronym: acronym, apiHostname: AppMain.apiHostname)
  }
}
