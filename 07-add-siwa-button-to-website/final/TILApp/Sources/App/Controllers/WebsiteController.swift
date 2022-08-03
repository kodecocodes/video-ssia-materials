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

import Vapor
import Fluent

struct WebsiteController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let authSessionsRoutes = routes.grouped(User.sessionAuthenticator())
    authSessionsRoutes.get(use: indexHandler)
    authSessionsRoutes.get("acronyms", ":acronymID", use: acronymHandler)
    authSessionsRoutes.get("users", ":userID", use: userHandler)
    authSessionsRoutes.get("users", use: allUsersHandler)
    authSessionsRoutes.get("categories", ":categoryID", use: categoryHandler)
    authSessionsRoutes.get("categories", use: allCategoriesHandler)
    authSessionsRoutes.get("login", use: loginHandler)
    authSessionsRoutes.post("logout", use: logoutHandler)
    authSessionsRoutes.get("register", use: registerHandler)
    authSessionsRoutes.post("register", use: registerPostHandler)
    
    let credentialsAuthRoutes = authSessionsRoutes.grouped(User.credentialsAuthenticator())
    credentialsAuthRoutes.post("login", use: loginPostHandler)
    
    let protectedRoutes = authSessionsRoutes.grouped(User.redirectMiddleware(path: "/login"))
    protectedRoutes.get("acronyms", "create", use: createAcronymHandler)
    protectedRoutes.post("acronyms", "create", use: createAcronymPostHandler)
    protectedRoutes.get("acronyms", ":acronymID", "edit", use: editAcronymHandler)
    protectedRoutes.post("acronyms", ":acronymID", "edit", use: editAcronymPostHandler)
    protectedRoutes.post("acronyms", ":acronymID", "delete", use: deleteAcronymHandler)
  }
  
  func indexHandler(_ req: Request) async throws -> View {
    let acronyms = try await Acronym.query(on: req.db).all()
    let context = IndexContext(title: "Homepage", acronyms: acronyms)
    return try await req.view.render("index", context)
  }
  
  func acronymHandler(_ req: Request) async throws -> View {
    guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else {
      throw Abort(.notFound)
    }
    let user = try await acronym.$user.get(on: req.db)
    let categories = try await acronym.$categories.get(on: req.db)
    let context = AcronymContext(title: acronym.long, acronym: acronym, user: user, categories: categories)
    return try await req.view.render("acronym", context)
  }
  
  func userHandler(_ req: Request) async throws -> View {
    guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
      throw Abort(.notFound)
    }
    let acronyms = try await user.$acronyms.get(on: req.db)
    let context = UserContext(title: user.name, user: user, acronyms: acronyms)
    return try await req.view.render("user", context)
  }
  
  func allUsersHandler(_ req: Request) async throws -> View {
    let users = try await User.query(on: req.db).all()
    let context = AllUsersContext(title: "All Users", users: users)
    return try await req.view.render("allUsers", context)
  }
  
  func categoryHandler(_ req: Request) async throws -> View {
    guard let category = try await Category.find(req.parameters.get("categoryID"), on: req.db) else {
      throw Abort(.notFound)
    }
    let acronyms = try await category.$acronyms.get(on: req.db)
    let context = CategoryContext(title: category.name, category: category, acronyms: acronyms)
    return try await req.view.render("category", context)
  }
  
  func allCategoriesHandler(_ req: Request) async throws -> View {
    let categories = try await Category.query(on: req.db).all()
    let context = AllCategoriesContext(title: "All Categories", categories: categories)
    return try await req.view.render("allCategories", context)
  }
  
  func createAcronymHandler(_ req: Request) async throws -> View {
    let context = CreateAcronymContext(title: "Create An Acronym")
    return try await req.view.render("createAcronym", context)
  }
  
  func createAcronymPostHandler(_ req: Request) async throws -> Response {
    let data = try req.content.decode(CreateAcronymData.self)
    let user = try req.auth.require(User.self)
    let acronym = try Acronym(short: data.short, long: data.long, userID: user.requireID())
    try await acronym.save(on: req.db)
    let id = try acronym.requireID()
    return req.redirect(to: "/acronyms/\(id)")
  }
  
  func editAcronymHandler(_ req: Request) async throws -> View {
    guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else {
      throw Abort(.notFound)
    }
    let context = EditAcronymContext(title: "Edit Acronym", acronym: acronym)
    return try await req.view.render("createAcronym", context)
  }
  
  func editAcronymPostHandler(_ req: Request) async throws -> Response {
    let updateData = try req.content.decode(CreateAcronymData.self)
    let user = try req.auth.require(User.self)
    let userID = try user.requireID()
    guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else {
      throw Abort(.notFound)
    }
    acronym.short = updateData.short
    acronym.long = updateData.long
    acronym.$user.id = userID
    try await  acronym.save(on: req.db)
    let id = try acronym.requireID()
    return req.redirect(to: "/acronyms/\(id)")
  }
  
  func deleteAcronymHandler(_ req: Request) async throws -> Response {
    guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else {
      throw Abort(.notFound)
    }
    try await acronym.delete(on: req.db)
    return req.redirect(to: "/")
  }
  
  func loginHandler(_ req: Request) async throws -> Response {
    let siwaContext = try buildSIWAContext(on: req)
    let context = LoginContext(title: "Log In", siwaContext: siwaContext)
    let expiryDate = Date().addingTimeInterval(300)
    let cookie = HTTPCookies.Value(string: siwaContext.state, expires: expiryDate, maxAge: 300, isHTTPOnly: true, sameSite: HTTPCookies.SameSitePolicy.none)
    let response: Response = try await req.view.render("login", context).encodeResponse(for: req)
    response.cookies["SIWA_STATE"] = cookie
    return response
  }
  
  func loginPostHandler(_ req: Request) async throws -> Response {
    if req.auth.has(User.self) {
      return req.redirect(to: "/")
    } else {
      let siwaContext = try buildSIWAContext(on: req)
      let context = LoginContext(title: "Log In", siwaContext: siwaContext)
      let expiryDate = Date().addingTimeInterval(300)
      let cookie = HTTPCookies.Value(string: siwaContext.state, expires: expiryDate, maxAge: 300, isHTTPOnly: true, sameSite: HTTPCookies.SameSitePolicy.none)
      let response: Response = try await req.view.render("login", context).encodeResponse(for: req)
      response.cookies["SIWA_STATE"] = cookie
      return response
    }
  }
  
  func logoutHandler(_ req: Request) -> Response {
    req.auth.logout(User.self)
    return req.redirect(to: "/")
  }
  
  func registerHandler(_ req: Request) async throws -> Response {
    let siwaContext = try buildSIWAContext(on: req)
    let context: RegisterContext
    if let message = req.query[String.self, at: "message"] {
      context = RegisterContext(message: message, siwaContext: siwaContext)
    } else {
      context = RegisterContext(siwaContext: siwaContext)
    }
    let response: Response = try await req.view.render("register", context).encodeResponse(for: req)
    let expiryDate = Date().addingTimeInterval(300)
    let cookie = HTTPCookies.Value(string: siwaContext.state, expires: expiryDate, maxAge: 300, isHTTPOnly: true, sameSite: HTTPCookies.SameSitePolicy.none)
    response.cookies["SIWA_STATE"] = cookie
    return response
  }
  
  func registerPostHandler(_ req: Request) async throws -> Response {
    do {
      try RegisterData.validate(content: req)
    } catch let error as ValidationsError {
      let message = error.description.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Unknown error"
      return req.redirect(to: "/register?message=\(message)")
    }
    let data = try req.content.decode(RegisterData.self)
    let password = try Bcrypt.hash(data.password)
    let user = User(name: data.name, username: data.username, password: password)
    try await user.save(on: req.db)
    req.auth.login(user)
    return req.redirect(to: "/")
  }
  
  private func buildSIWAContext(on req: Request) throws -> SIWAContext {
    let state = [UInt8].random(count: 32).base64
    let scopes = "name email"
    guard let clientID = Environment.get("WEBSITE_APPLICATION_IDENTIFIER") else {
      req.logger.error("WEBSITE_APPLICATION_IDENTIFIER not set")
      throw Abort(.internalServerError)
    }
    guard let redirectURI = Environment.get("SIWA_REDIRECT_URL") else {
      req.logger.error("SWIA_REDIRECT_URL not set")
      throw Abort(.internalServerError)
    }
    let siwa = SIWAContext(clientID: clientID, scopes: scopes, redirectURL: redirectURI, state: state)
    return siwa
  }
}

struct SIWAContext: Encodable {
    let clientID: String
    let scopes: String
    let redirectURL: String
    let state: String
}
