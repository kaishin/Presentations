/*:
 ## Functional Programming & DSLs
 - Languages that support functional programming lend themselves particularly well to building DSLs.
 - The benefit of using functional pipelines that are immutable and predictable.
 - Possibility to compose at different API layers, for instance using function composition and other forms of framework defined composition mechanisms.
 ## Result Builders
 - Initially called "function builders"
 - Introduced in Swift 5.4 (spring 2021) after the review process of proposal [SE-0289](https://github.com/apple/swift-evolution/blob/main/proposals/0289-result-builders.md)
 - Designed primarily for building DSLs (Domain Specific Language).
 - Can be used in many more scenarios.
 */
//: ### Declaration Syntax
import Foundation

@resultBuilder
struct StringBuilder {
  // The only requirement.
  // `buildBlock` combines multiple partial results into one.
  static func buildBlock(
    _ components: String...
  ) -> String {
    components.joined(separator: " ")
  }
}
/*:
 Can be applied to a function, method, getter, or closure.
 Function example:
 */
@StringBuilder
func helloWorld() -> String {
  "Hello"
  "world"
  "2023"
}

helloWorld()

@StringBuilder
func hello(_ name: String) -> String {
  "Hello"
  name
}

hello("Func Prog Sweden")

@StringBuilder
func draft_countLabel(
  _ count: Int,
  countable: String
) -> String {
  // count?
  countable
}
//: Enter `buildExpression`. Creates a partial result from a single expression.
//:
//: `func buildExpression(_ expression: Int) -> String`
//extension StringBuilder {
//  static func buildExpression(_ expression: Int) -> String {
//    expression.description
//  }
//}
//: `buildExpression` wraps every bare expression before passing it to `buildBlock`.
//: - It allows you to support _multiple inputs_.
extension StringBuilder {
  static func buildExpression(
    _ expression: Int
  ) -> String {
    expression.description
  }

  static func buildExpression(_ expression: String
  ) -> String {
    expression
  }
}

@StringBuilder
func countLabel(
  _ count: Int,
  countable: String
) -> String {
  count
  countable
}

countLabel(3, countable: "cars")
countLabel(1, countable: "cars")

@StringBuilder
func draft_advancedCountLabel(
  _ count: Int,
  countableSingular: String,
  countablePlural: String
) -> String {
//  count
//  if count == 1 {
//    countableSingular
//  } else {
//    countablePlural
//  }
}
//: ## Result builders restrict all keywords not explicitly supported.
//: To support `if`/`else`, we need to extend our builder with `buildEither`.
extension StringBuilder {
  static func buildEither(first component: String) -> String {
    component
  }

  static func buildEither(second component: String) -> String {
    component
  }
}

@StringBuilder
func advancedCountLabel(
  _ count: Int,
  countableSingular: String,
  countablePlural: String
) -> String {
  count
  if count == 1 {
    countableSingular
  } else {
    countablePlural
  }
}

advancedCountLabel(
  3,
  countableSingular: "car",
  countablePlural: "cars"
)

advancedCountLabel(
  1,
  countableSingular: "car",
  countablePlural: "cars"
)
/*:
 Beside `buildBlock`, `buildExpression`, and `buildEither`, these are some of the other methods available:
 - `buildOptional`
 - `buildArray`
 - `buildLimitedAvailability`
 - `buildFinalResult`
 */
extension StringBuilder {
  static func buildFinalResult(_ component: String) -> String {
    component
  }

  static func buildFinalResult(_ component: String) -> Int {
    component.count
  }
}

@StringBuilder
func count(_ name: String) -> Int {
  hello(name)
}

count("Func Prog Sweden")
//: `buildFinalResult` allows you to support _multiple outputs_.
//:
//: [◀️](@previous) [▶️](@next)
