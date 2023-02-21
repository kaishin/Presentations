/*:
 ## A Shape Builder
 So far we only used concrete types. Result builders also work with **abstract types** and **generics**.

 Let's give it a try!
 */
import Foundation
import PlaygroundSupport
import SwiftUI
/*: We start off by defining a protocol interface: `Drawable`.
 For a type to be drawable, it needs to have:
 - A _size_.
 - A set of drawing instructions. We will use SwiftUI's built-in `Path` type.
 */
protocol Drawable {
  var size: CGSize { get }
  func draw() -> Path
}

extension Drawable {
  // For SwiftUI drawing purposes, every instance needs an ID.
  // In this demo a random value will be enough. Don't do this in production code.
  var id: UUID { .init() }
}
/*:
 To implement our shape builder, we will use another method: `buildPartialBlock`.
 - Introduced in Swift 5.7 ([SE-0348](https://github.com/apple/swift-evolution/blob/main/proposals/0348-buildpartialblock.md))
 - Allows components of a block to be combined pairwise.
 - Has two variants: one that starts with a single component, and one that works similar to a `reduce` function, with `accumulated` and `next` parameters.
 - Particularly useful when used with generics.
 */
//: Our shape builder will help us build arrays of drawable types.
@resultBuilder
struct ShapeBuilder {
  static func buildPartialBlock(
    first content: some Drawable
  ) -> [any Drawable] {
    [content]
  }

  static func buildPartialBlock(
    accumulated: [any Drawable],
    next: some Drawable
  ) -> [any Drawable] {
    var copy = accumulated
    copy.append(next)
    return copy
  }
}
//: Before we try out our builder, we need a concrete type that conforms to `Drawable`.
struct Square: Drawable {
  let id: UUID = .init()
  let size: CGSize

  func draw() -> Path {
    // Check out https://github.com/mkj-is/PathBuilder for a result builder version.
    Path {
      $0.move(to: CGPoint(x: 0, y: 0))
      $0.addLine(to: CGPoint(x: 0, y: size.height))
      $0.addLine(to: CGPoint(x: size.width, y: size.height))
      $0.addLine(to: CGPoint(x: size.width, y: 0))
      $0.closeSubpath()
    }
  }
}
//: Then we need to annotate a function with the builder.
@ShapeBuilder
func twoSquares() -> [any Drawable] {
  Square(size: .init(width: 400, height: 400))
  Square(size: .init(width: 200, height: 200))
}

twoSquares()
//: Now we have the data representation of the shape, but wouldn't be cool to actually render it? 🎨
struct ShapeCanvas {
//: We hold all the drawables in an array.
  let shapes: [any Drawable]
//: We use `ShapeBuilder` in the initializer to create the array.
  init(
    @ShapeBuilder draw: () -> [any Drawable]
  ) {
    self.shapes = draw()
  }

//: Finally we implement a render method that will interface with the UI framework.
  @ViewBuilder
  func render() -> some View {
    let colors = [Color.purple, .green, .yellow, .red, .blue]

    ZStack {
      ForEach(shapes, id: \.id) { shape in
        shape.draw()
          .stroke(colors.randomElement()!, lineWidth: 10)
          .frame(
            width: shape.size.width,
            height: shape.size.height
          )
      }
    }
    .frame(width: 500, height: 500)
  }
}

// Extra conformance to render in Playgrounds
extension ShapeCanvas: CustomPlaygroundDisplayConvertible {
  @MainActor
  public var playgroundDescription: Any {
    let renderer = ImageRenderer(content: render())
    return renderer.nsImage!
  }
}
//: Time to render!
ShapeCanvas(draw: twoSquares)

let drawing_2 = ShapeCanvas {
  Square(size: .init(width: 100, height: 100))
  Square(size: .init(width: 200, height: 200))
  Square(size: .init(width: 300, height: 300))
  Square(size: .init(width: 400, height: 400))
  Square(size: .init(width: 500, height: 500))
}
drawing_2
//: Let's define another type that conforms to `Drawable`.
struct Lozenge: Drawable {
  let id: UUID = .init()
  let size: CGSize

  func draw() -> Path {
    Path {
      $0.move(to: CGPoint(x: size.width / 2, y: 0))
      $0.addLine(to: CGPoint(x: size.width * 0.1, y: size.height / 2))
      $0.addLine(to: CGPoint(x: size.width / 2, y: size.height))
      $0.addLine(to: CGPoint(x: size.width * 0.9, y: size.height / 2))
      $0.closeSubpath()
    }
  }
}
let drawing_3 = ShapeCanvas {
  Square(size: .init(width: 50, height: 50))
  Lozenge(size: .init(width: 200, height: 200))
  Square(size: .init(width: 250, height: 250))
  Lozenge(size: .init(width: 400, height: 400))
  Square(size: .init(width: 350, height: 350))
}
drawing_3
//: We can conform _any_ type to `Drawable` to extend our shape builder.
@available(macOS 16, *)
extension String: Drawable {
  static let padding: Double = 5
  static let pillSize: Double = 20

  var size: CGSize {
    .init(
      width: Double(count) * (Self.pillSize + Self.padding),
      height: Self.pillSize
    )
  }

  public func draw() -> Path {
    Path {
      for i in 0...count-1 {
        $0.addEllipse(
          in: .init(
            origin: .init(x: Double(i) * (Self.pillSize + Self.padding), y: 0),
            size: .init(width: Self.pillSize, height: Self.pillSize)
          )
        )
      }
    }
  }
}

struct StackingShapeCanvas: CustomPlaygroundDisplayConvertible {
  //: We hold all the drawables in an array.
  let shapes: [any Drawable]
  //: We use `ShapeBuilder` in the initializer to create the array.
  init(
    @ShapeBuilder draw: () -> [any Drawable]
  ) {
    self.shapes = draw()
  }

  //: Finally we implement a render method that will interface with the UI framework.
  @ViewBuilder
  func render() -> some View {
    VStack(spacing: 10) {
      ForEach(shapes, id: \.id) { shape in
        shape.draw()
          .fill(.primary)
          .frame(
            width: shape.size.width,
            height: shape.size.height
          )
      }
    }
//    .frame(width: 500, height: 500)
  }

  @MainActor
  public var playgroundDescription: Any {
    let renderer = ImageRenderer(content: render())
    return renderer.nsImage!
  }
}

let secretMessage = StackingShapeCanvas {
  "Hello"
  "This text is secret"
  "Very secret"
}
secretMessage

let sword = StackingShapeCanvas {
  Lozenge(size: .init(width: 20, height: 20))
  Lozenge(size: .init(width: 20, height: 20))
  Lozenge(size: .init(width: 20, height: 20))
  Lozenge(size: .init(width: 25, height: 25))
  Lozenge(size: .init(width: 25, height: 25))
  Lozenge(size: .init(width: 25, height: 25))
  "Sword"
  Lozenge(size: .init(width: 25, height: 25))
  Lozenge(size: .init(width: 30, height: 30))
}
sword
//: The possibilities are endless!
/*:
 Result builders make APIs _more expressive_ while tapping into all the benefits of functional programming, such as immutability, predictability, and composability.

 ### ...but there a couple of gotchas.
 - **Steeper learning curve**. The black-box effect.
 - Autocomplete may be less useful inside a result builder compared to dot syntax, functional chaining, etc. (but it's improving!).
*/
//: [◀️](@previous) [▶️](@next)
