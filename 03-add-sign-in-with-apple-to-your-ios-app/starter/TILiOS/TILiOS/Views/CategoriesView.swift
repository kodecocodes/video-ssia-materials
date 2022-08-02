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

struct CategoriesView: View {
  @State private var showingSheet = false
  @State private var categories: [Category] = []
  @State private var showingCategoryErrorAlert = false
  let apiHostname: String
  let categoriesRequest: ResourceRequest<Category>
  
  init(apiHostname: String) {
    self.apiHostname = apiHostname
    self.categoriesRequest = ResourceRequest<Category>(apiHostname: apiHostname, resourcePath: "categories")
  }

  var body: some View {
    NavigationView {
      List(categories, id: \.id) { category in
        Text(category.name)
          .font(.title2)
      }
      .navigationTitle("Categories")
      .toolbar {
        Button(
          action: {
            showingSheet.toggle()
          }, label: {
            Image(systemName: "plus")
          })
      }
    }
    .sheet(isPresented: $showingSheet) {
      CreateCategoryView(apiHostname: self.apiHostname)
        .onDisappear {
          Task {
            await loadData()
          }
        }
    }
    .task {
      await loadData()
    }
    .alert(isPresented: $showingCategoryErrorAlert) {
      Alert(title: Text("Error"), message: Text("There was an error getting the acronyms"))
    }
  }

  @MainActor
  func loadData() async {
    do {
      let categories = try await categoriesRequest.getAll()
      self.categories = categories
    } catch {
      self.showingCategoryErrorAlert = true
    }
  }
}

struct CategoriesView_Previews: PreviewProvider {
  static var previews: some View {
    CategoriesView(apiHostname: AppMain.apiHostname)
  }
}
