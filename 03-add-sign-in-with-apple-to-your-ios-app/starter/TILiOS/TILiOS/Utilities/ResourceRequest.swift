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

struct ResourceRequest<ResourceType> where ResourceType: Codable {
  let resourceURL: URL
  
  init(apiHostname: String, resourcePath: String) {
    let baseURL = "\(apiHostname)/api/"
    guard let resourceURL = URL(string: baseURL) else {
      fatalError("Failed to convert baseURL to a URL")
    }
    self.resourceURL =
    resourceURL.appendingPathComponent(resourcePath)
  }
  
  func getAll() async throws -> [ResourceType] {
    let (data, _) = try await URLSession.shared.data(from: resourceURL)
    return try JSONDecoder().decode([ResourceType].self, from: data)
  }
  
  func save<CreateType>(_ saveData: CreateType, auth: Auth) async throws -> ResourceType where CreateType: Codable {
    guard let token = auth.token else {
      auth.logout()
      throw AuthError.notLoggedIn
    }
    var urlRequest = URLRequest(url: resourceURL)
    urlRequest.httpMethod = "POST"
    urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    urlRequest.httpBody = try JSONEncoder().encode(saveData)
    
    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw ResourceRequestError.noData
    }
    guard httpResponse.statusCode == 200 else {
      if httpResponse.statusCode == 401 {
        auth.logout()
        throw AuthError.notLoggedIn
      }
      throw ResourceRequestError.badResponse
    }
    return try JSONDecoder().decode(ResourceType.self, from: data)
  }
}
