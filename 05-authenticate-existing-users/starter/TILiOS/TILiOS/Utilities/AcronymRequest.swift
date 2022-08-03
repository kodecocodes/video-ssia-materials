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
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation

struct AcronymRequest {
  let resource: URL
  
  init(acronymID: UUID, apiHostname: String) {
    let resourceString = "\(apiHostname)/api/acronyms/\(acronymID)"
    guard let resourceURL = URL(string: resourceString) else {
      fatalError("Unable to createURL")
    }
    self.resource = resourceURL
  }
  
  func update(with updateData: CreateAcronymData, auth: Auth) async throws -> Acronym {
    guard let token = auth.token else {
      auth.logout()
      throw AuthError.notLoggedIn
    }
    var urlRequest = URLRequest(url: resource)
    urlRequest.httpMethod = "PUT"
    urlRequest.httpBody = try JSONEncoder().encode(updateData)
    urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw CategoryAddError.invalidResponse
    }
    guard httpResponse.statusCode == 200 else {
      if httpResponse.statusCode == 401 {
        auth.logout()
        throw AuthError.notLoggedIn
      }
      throw ResourceRequestError.badResponse
    }
    return try JSONDecoder().decode(Acronym.self, from: data)
  }
  
  func remove(category: Category, auth: Auth) async throws {
    guard let categoryID = category.id else {
      throw CategoryAddError.noID
    }
    guard let token = auth.token else {
      auth.logout()
      throw AuthError.notLoggedIn
    }
    let url = resource
      .appendingPathComponent("categories")
      .appendingPathComponent("\(categoryID)")
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "DELETE"
    urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    let (_, response) = try await URLSession.shared.data(for: urlRequest)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw CategoryAddError.invalidResponse
    }
    guard httpResponse.statusCode == 204 else {
      if httpResponse.statusCode == 401 {
        auth.logout()
        throw AuthError.notLoggedIn
      }
      throw CategoryAddError.invalidResponse
    }
  }
  
  func delete(auth: Auth) async throws {
    guard let token = auth.token else {
      auth.logout()
      return
    }
    var urlRequest = URLRequest(url: resource)
    urlRequest.httpMethod = "DELETE"
    urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    _ = try await URLSession.shared.data(for: urlRequest)
  }
  
  func getUser() async throws -> User {
    let url = resource.appendingPathComponent("user")
    let (data, _) = try await URLSession.shared.data(from: url)
    let decoder = JSONDecoder()
    return try decoder.decode(User.self, from: data)
  }
  
  func getCategories() async throws -> [Category] {
    let url = resource.appendingPathComponent("categories")
    let (data, _) = try await URLSession.shared.data(from: url)
    let decoder = JSONDecoder()
    return try decoder.decode([Category].self, from: data)
  }
  
  func add(category: Category, auth: Auth) async throws {
    guard let token = auth.token else {
      auth.logout()
      return
    }
    guard let categoryID = category.id else {
      throw CategoryAddError.noID
    }
    let url = resource.appendingPathComponent("categories").appendingPathComponent("\(categoryID)")
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let (_, response) = try await URLSession.shared.data(for: urlRequest)
    
    guard let httpResponse = response as? HTTPURLResponse else {
      throw CategoryAddError.invalidResponse
    }
    guard httpResponse.statusCode == 201 else {
      if httpResponse.statusCode == 401 {
        auth.logout()
      }
      throw CategoryAddError.invalidResponse
    }
  }
}
