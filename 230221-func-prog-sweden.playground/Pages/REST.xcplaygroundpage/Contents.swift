/*:
 ## Composing Result Builders
 Since result builders are implemented as a collection of functions,
 the result output of one builder can be nested in another of the same types.
*/
import Foundation
//: Let's look at an example. Consider the following `request` type:
struct Request {
  var method: String
  var headers: [String: String]
  var path: String

  static func factory() -> Self {
    .init(
      method: "GET",
      headers: [:],
      path: "/"
    )
  }
}
//: And the following function transform:
typealias RequestTransform = (Request) throws -> (Request)
//: We can then create result builder that builds transforms:
@resultBuilder
struct RequestBuilder {
  static func buildBlock(
    _ components: RequestTransform...
  ) -> RequestTransform {
    {
      try components.reduce($0) { transformed, component in
        return try component(transformed)
      }
    }
  }
}
//: Now let's define some example transforms
// Adds or replaces a request's header key/value pair
func requestHeader(
  key: String,
  value: String
) -> RequestTransform {
  { request in
    var copy = request
    copy.headers[key] = value
    return copy
  }
}
// Adds or replaces a request's method
func requestMethod(
  _ method: String
) -> RequestTransform {
  { request in
    var copy = request
    copy.method = method
    return copy
  }
}

// Adds or replaces a request's path
func requestPath(
  _ path: String
) -> RequestTransform {
  { request in
    var copy = request
    copy.path = path
    return copy
  }
}
//: Now let's define a couple of endpoints
/// List all users.
@RequestBuilder
func usersEndpoint() -> RequestTransform {
  requestPath("/users")
  requestMethod("GET")
}
/// List all pets.
@RequestBuilder
func petsEndpoint() -> RequestTransform {
  requestPath("/pets")
  requestMethod("GET")
}

let usersRequest = try usersEndpoint()(.factory())
let petsRequest = try petsEndpoint()(.factory())
//: Now suppose both of these endpoint need an auth token.
//: We can define a new transform to handle auth.
@RequestBuilder
func auth(_ token: String) -> RequestTransform {
  requestHeader(key: "Authorization", value: "Bearer \(token)")
}
//: This new builder can now be used in our methods.
/// List all users.
@RequestBuilder
func usersEndpoint(
  token: String
) -> RequestTransform {
  auth(token)
  requestPath("/users")
  requestMethod("GET")
}
/// List all pets.
@RequestBuilder
func petsEndpoint(token: String) -> RequestTransform {
  auth(token)
  requestPath("/pets")
  requestMethod("GET")
}

let authUsersRequest = try usersEndpoint(token: "abc")(.factory())
let authPetsRequest = try petsEndpoint(token: "abc")(.factory())
//: Suppose we have an endpoint to get a specific user `/users/:id`.
//: We can define it like the following:
/// Get user by ID
@RequestBuilder
func userEndpoint_v1(
  token: String,
  id: Int
) -> RequestTransform {
  auth(token)
  requestPath("/users/\(id)")
  requestMethod("GET")
}

let getFirstUser = try userEndpoint_v1(token: "abc", id: 0)(.factory())
//: As the number of requests we add grows, the current API surface will result in a lot of repetition.
//: Let's see what we can do about that.
//: ## Path Builder
@resultBuilder
struct PathBuilder {
  // The only requirement.
  // `buildBlock` combines multiple partial results into one.
  static func buildBlock(_ components: String...) -> String {
    components.joined(separator: "/")
  }
}

func betterRequestPath(
  @PathBuilder builder: @escaping () -> String
) -> RequestTransform {
  { request in
    var copy = request
    copy.path = builder()
    return copy
  }
}

let usersRootPath = "users"

// Adds or replaces a request's method
func GET() -> RequestTransform {
  requestMethod("GET")
}

/// List all users.
@RequestBuilder
func usersEndpoint_v1(token: String) -> RequestTransform {
  GET()
  auth(token)

  betterRequestPath {
    usersRootPath
  }
}

try usersEndpoint_v1(token: "abc")(.factory())
//: Now let us go back to our user endpoint.
/// Get user by ID
@RequestBuilder
func userEndpoint_v2(
  token: String,
  id: Int
) -> RequestTransform {
  GET()
  auth(token)
  betterRequestPath {
    usersRootPath
//  id
  }
}
//: We need to extend our path builder to support other types such as `Int`.
//: ## But why stop at `Int`?
extension PathBuilder {
  static func buildExpression(_ expression: CustomStringConvertible) -> String {
    expression.description
  }
}

@RequestBuilder
func userEndpoint_v3(
  token: String,
  id: Int
) -> RequestTransform {
  GET()
  auth(token)
  betterRequestPath {
    usersRootPath
    id
  }
}

try userEndpoint_v3(
  token: "abc",
  id: 182
)(.factory())
//: We can also define resources as an enum.
enum Resource: String, CustomStringConvertible {
  case posts
  case comments
  case followers

  var description: String {
    rawValue
  }
}

@RequestBuilder
func userCommentEndpoint(
  token: String,
  id: Int,
  commentId: UUID
) -> RequestTransform {
  GET()
  auth(token)
  betterRequestPath {
    usersRootPath
    id
    Resource.comments
    commentId
  }
}

try userCommentEndpoint(
  token: "abc",
  id: 0,
  commentId: .init()
)(.factory())
//: While we're at it let's improve our `PathBuilder` by adding a leading `/` and validating the output.
import RegexBuilder

extension PathBuilder {
  static func buildFinalResult(_ component: String) -> String {
    // /[a-zA-Z0-9,.@?=\/]+/
    let validURLRegex = Regex {
      OneOrMore {
        CharacterClass(
          .anyOf(",.@?=/-_"),
          ("a"..."z"),
          ("A"..."Z"),
          ("0"..."9")
        )
      }
    }

    guard component.wholeMatch(of: validURLRegex) != nil
    else {
      fatalError("Invalid URL path component in \(component)")
    }

    return "/" + component
  }
}
//: Now if we define an invalid path, the result builder should throw a fatal error during compile time.
@RequestBuilder
func invalidEndpoint() -> RequestTransform {
  GET()
  betterRequestPath {
    usersRootPath
//    "😎"
  }
}

try invalidEndpoint()(.factory())
//: [◀️](@previous) [▶️](@next)
