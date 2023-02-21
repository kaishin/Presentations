/*:
 ### Previous Talk
 ## The Power of Functional Composition in Swift
*/
struct Request {}
typealias RequestTransform = (Request) throws -> Request
/*:
 ```swift
  func someRequest(
    token: String,
    adminKey: String
  ) -> RequestTransform {
    pipe(
      postJSONBody,
      somePath,
      adminKeyHeader(adminKey)
    )
  }
 ```
*/
// For a quick introduction to Swift, check my presentation from last year.
//: [◀️](@previous) [▶️](@next)
