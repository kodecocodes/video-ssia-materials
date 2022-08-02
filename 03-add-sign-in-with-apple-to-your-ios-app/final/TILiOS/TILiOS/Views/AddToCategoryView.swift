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

struct AddToCategoryView: View {
  var acronym: Acronym
  let apiHostname: String
  @State var categories: [Category] = []
  @State var selectedCategories: [Category]
  @State private var showingCategoryErrorAlert = false
  @State private var showingAddCategoryToAcronymErrorAlert = false
  @EnvironmentObject var auth: Auth
  @Environment(\.presentationMode) var presentationMode

  var body: some View {
    List(categories, id: \.id) { category in
      HStack {
        Text(category.name)
        Spacer()
        if selectedCategories.contains(where: { $0.id == category.id }) {
          Image(systemName: "checkmark")
        }
      }
      .contentShape(Rectangle())
      .onTapGesture {
        guard let acronymID = acronym.id else {
          fatalError("Acronym did not have an ID")
        }
        let acronymRequest = AcronymRequest(acronymID: acronymID, apiHostname: self.apiHostname)
        if !selectedCategories.contains(where: { $0.id == category.id }) {
          Task {
            do {
              try await acronymRequest.add(category: category, auth: auth)
              presentationMode.wrappedValue.dismiss()
            } catch {
              self.showingAddCategoryToAcronymErrorAlert = true
            }
          }
        }
      }
    }
    .navigationTitle("Add To Category")
    .task {
      await loadData()
    }
    .alert(isPresented: $showingCategoryErrorAlert) {
      Alert(title: Text("Error"), message: Text("There was an error getting the categories"))
    }
    .alert(isPresented: $showingAddCategoryToAcronymErrorAlert) {
      let message = """
        There was an error adding the acronym
        to the category
        """
      return Alert(title: Text("Error"), message: Text(message))
    }
  }

  @MainActor
  func loadData() async {
    let categoriesRequest = ResourceRequest<Category>(apiHostname: self.apiHostname, resourcePath: "categories")
    do {
      self.categories = try await categoriesRequest.getAll()
    } catch {
      self.showingCategoryErrorAlert = true
    }
  }
}

struct AddToCategoryView_Previews: PreviewProvider {
  static var previews: some View {
    AddToCategoryView(
      acronym: dummyAcronyms[0], apiHostname: AppMain.apiHostname,
      categories: dummyCategories,
      selectedCategories: Array(dummyCategories.prefix(1)))
  }
}
