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

struct AcronymsView: View {
  @State private var showingSheet = false
  @State private var showingAcronymErrorAlert = false
  @EnvironmentObject var auth: Auth
  @State private var acronyms: [Acronym] = []
  let apiHostname: String
  let acronymsRequest: ResourceRequest<Acronym>
  
  init(apiHostname: String) {
    self.apiHostname = apiHostname
    self.acronymsRequest = ResourceRequest<Acronym>(apiHostname: apiHostname, resourcePath: "acronyms")
  }
  
  var body: some View {
    NavigationView {
      List {
        // swiftlint:disable:next trailing_closure
        ForEach(acronyms, id: \.id) { acronym in
          NavigationLink(destination: AcronymDetailView(acronym: acronym, apiHostname: self.apiHostname).onDisappear(perform: {
            Task {
              await loadData()
            }
          })) {
            VStack(alignment: .leading) {
              Text(acronym.short).font(.title2)
              Text(acronym.long).font(.caption)
            }
          }
        }
        .onDelete(perform: { indexSet in
          for index in indexSet {
            if let id = acronyms[index].id {
              let acronymDetailRequester = AcronymRequest(acronymID: id, apiHostname: self.apiHostname)
              Task {
                try await acronymDetailRequester.delete(auth: auth)
              }
            }
          }
          acronyms.remove(atOffsets: indexSet)
        })
      }
      .navigationTitle("Acronyms")
      .toolbar {
        Button(
          action: {
            showingSheet.toggle()
          }, label: {
            Image(systemName: "plus")
          })
      }
    }
    .modifier(ResponsiveNavigationStyle())
    .sheet(isPresented: $showingSheet) {
      CreateAcronymView(apiHostname: self.apiHostname)
        .onDisappear {
          Task {
            await loadData()
          }
        }
    }
    .task {
      await loadData()
    }
    .alert(isPresented: $showingAcronymErrorAlert) {
      Alert(title: Text("Error"), message: Text("There was an error getting the acronyms"))
    }
  }
  
  @MainActor
  func loadData() async {
    do {
      let acronyms = try await acronymsRequest.getAll()
      self.acronyms = acronyms
    } catch {
      self.showingAcronymErrorAlert = true
    }
  }
}

struct AcronymsView_Previews: PreviewProvider {
  static var previews: some View {
    AcronymsView(apiHostname: AppMain.apiHostname)
  }
}
