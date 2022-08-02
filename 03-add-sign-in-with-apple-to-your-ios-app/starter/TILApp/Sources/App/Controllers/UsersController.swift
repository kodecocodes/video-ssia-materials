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
import JWT

struct UsersController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let usersRoutes = routes.grouped("api", "users")
    usersRoutes.post(use: createHandler)
    usersRoutes.get(use: getAllHandler)
    usersRoutes.get(":userID", use: getHandler)
    usersRoutes.get(":userID", "acronyms", use: getAcronymsHandler)
    usersRoutes.post("siwa", use: signInWithApple)
    
    let basicAuthMiddleware = User.authenticator()
    let basicAuthGroup = usersRoutes.grouped(basicAuthMiddleware)
    basicAuthGroup.post("login", use: loginHandler)
  }
  
  func createHandler(_ req: Request) async throws -> User.Public {
    let user = try req.content.decode(User.self)
    user.password = try Bcrypt.hash(user.password)
    try await user.save(on: req.db)
    return user.convertToPublic()
  }
  
  func getAllHandler(_ req: Request) async throws -> [User.Public] {
    try await User.query(on: req.db).all().convertToPublic()
  }
  
  func getHandler(_ req: Request) async throws -> User.Public {
    guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
      throw Abort(.notFound)
    }
    return user.convertToPublic()
  }
  
  func getAcronymsHandler(_ req: Request) async throws -> [Acronym] {
    guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
      throw Abort(.notFound)
    }
    return try await user.$acronyms.get(on: req.db)
  }
  
  func loginHandler(_ req: Request) async throws -> Token {
    let user = try req.auth.require(User.self)
    let token = try Token.generate(for: user)
    try await token.save(on: req.db)
    return token
  }
  
  func signInWithApple(_ req: Request) async throws -> Token {
    let data = try req.content.decode(SignInWithAppleToken.self)
    guard let appIdentifier = Environment.get("IOS_APPLICATION_IDENTIFIER") else {
      throw Abort(.internalServerError)
    }
    let siwaToken = try await req.jwt.apple.verify(data.token, applicationIdentifier: appIdentifier)
    let user: User
    if let userFound = try await User.query(on: req.db).filter(\.$siwaIdentifier == siwaToken.subject.value).first() {
      user = userFound
    } else {
      guard let email = siwaToken.email, let name = data.name else {
        throw Abort(.badRequest)
      }
      let newUser = User(name: name, username: email, password: UUID().uuidString, siwaIdentifier: siwaToken.subject.value)
      try await newUser.save(on: req.db)
      user = newUser
    }
    let token = try Token.generate(for: user)
    try await token.save(on: req.db)
    return token
  }
  
}

struct SignInWithAppleToken: Content {
    let token: String
    let name: String?
}
