footer: Func Prog Sweden – April 2022
build-lists: true
# The Power of Function Composition in Swift
### By Reda Lemeden

---
## Mandatory slide about myself.
![Fill](https://redalemeden.com/social-cards/default.jpg)

- Developer (~15 years)
- ActionScript -> JavaScript -> Objective-C / Ruby -> Swift
- SwiftUI / iOS (@Circle) / Server-side Swift
- 🌍 redalemeden.com
- 🐦 @kaishin

---
## [Fit] Let’s get going!

![Fill](https://c.tenor.com/c5nS7cjT5ZAAAAAC/turtle-dog.gif)
![Fill](https://c.tenor.com/c5nS7cjT5ZAAAAAC/turtle-dog.gif)
![Fill](https://c.tenor.com/c5nS7cjT5ZAAAAAC/turtle-dog.gif)

---

## Swift you say?

![Fill](https://windowsunited.de/wp-content/uploads/sites/3/2020/03/apple_swift_logo_teaser_image.jpg)

- 1.0 released in 2014, 2.0 released and open-sourced in 2015 
- Mac  + Linux (>2.2) + Windows (>5.3)
- Supports OOP, “POP”, and FP
- Statically typed
- Interop with C, Objective-C, Python, JS (via `JSCOntext`), C++ (WIP)

---

## Where You Can Use Swift

![Fill](https://windowsunited.de/wp-content/uploads/sites/3/2020/03/apple_swift_logo_teaser_image.jpg)

- Apple platforms application development
- Server-side (`SSWG`, `Vapor`, etc.)
- Serverless (Official AWS Lambda support)
- Cross-platform CLI tools
- WebAssembly (`swiftwasm.org`)

---
## Notable Swift Features I

- Immutable value types
- Mutable reference types
- First-class functions
- Generics
- Protocols
- Type Extensions

---
## Notable Swift Features II

- Lower level pointer APIs
- `async`/`await`
- ABI stable since 5.0
- Operator overload + Custom operators
- Variadic parameters
- Emoji support. `🐢()` is valid code.

---
## Functions in Swift

```swift
func graze() { 
  /* ... */ 
}

// or...

let graze = { /* ... */ }

// Both of these can be called as:

graze()
``` 

---
## Every function has a type.
## `Parameter Types -> Return Type` 

---

```swift
func graze() {} 
// () -> Void

func add(_ lhs: Int, rhs: Int) -> Int { lhs + rhs } 
// (Int, Int) -> Int
```

---
# First-class Functions
- Functions in Swift support _all the standard operations_ available to other types.


# Higher-order Functions
- Functions can be passed as arguments or returned from other functions.

---
## Functions as Values

```swift
let doMath: (Int, Int) -> Int
doMath = { $0 - $1 } // Immutable ❌

var doMath = add
doMath = { $0 - $1 } // Mutable ✅
```

---
## Functions as Parameters

```swift
let graze = {}

func doSomething(_ action: () -> Void) {
  action()
}

doSomething(graze)
```
---
## Functions as Return Values

```swift
func drop(count: Int = 1) -> (String) -> String {
  return {
    String($0.dropLast(count))
  }
}

let dropLast = drop()
dropLast("turtle") // -> "turtl"

let drop2Last = drop(count: 2)
drop2Last("turtle") // -> "turt"

let drop10Last = drop(quantity: 10) 
drop10Last("turtle") // -> ""
```
---
## Function composition 

A series of functions where each:

1. receives input, 
2. does some additional computation, 
3. then hands over the output to the next function in the pipe.

---

[.code-highlight: 1-3]
[.code-highlight: 4-10]

```swift
let dropLast = drop()
let drop2Last = drop(count: 2)
let drop10Last = drop(quantity: 10) 

func drop13Last(_ value: String) -> String {
  drop10Last(drop2Last(dropLast(value)))
}

drop13Last("The slow green turtle jumps...not")
// -> "The slow green turtl"

```

---

![Fit](https://c.tenor.com/T_FU7AaE4-8AAAAC/travel-turtle.gif)

---
## Point-free (Tacit Programming)
When a function definition is achieved solely through composing other functions (no explicit parameters).

```swift
// Not point-free (Imperative)
func drop13Last(_ value: String) -> String {
  drop10Last(drop2Last(dropLast(value)))
}

// Point-free (Declarative)
let drop13Last = compose(drop10Last, drop2Last, dropLast)
```
---
# Case Study: REST API Client
---
## What’s a REST API client?

A client-side API that allows us to access a collection of _RESTful resources_ (endpoints) via the networking interface.

---

The task of calling a REST API endpoint typically involves following these steps.

1. Create a client-side representation of a given API endpoint.
2. Add logic to transform input data into a platform-specific request object.

---

### Step 1: Create a client-side representation of the endpoint.

* Input data to be sent with the request.
* Output to expect from the response.

`(Input) -> Output`

---

### Example

An endpoint that takes a `UUID` and returns a `Turtle` can be represented as:

```swift
func getTurtle(with id: UUID) -> Turtle {
  // ...
}
```


---
### Step 2: Transform input into a request abstraction

```swift
struct Request {
  var method: HTTPMethod // enum: GET, POST, etc.
  var path: [CustomStringConvertible] // [String]
  var queryItems: [String: String]
  var headers: [String: String]
  var body: Data?
}
```

---
## `(UUID) -> Request` 
---
```swift
func getTurtleRequest(with id: UUID) -> Request
```
---
## Request Configuration

The Imperative Approach

```swift
func getTurtleRequest(with id: UUID) -> Request {
  var request = Request()
  request.method = .get
  request.path = "turtles/\(id)"
  return request
}
```
---

The Declarative approach

```swift
func getTurtleRequest(with id: UUID) -> RequestTransform {
  compose(
    (Request) -> (Request),
    (Request) -> (Request), 
    (Request) -> (Request)
  ) // (Request) -> (Request)
}
```

---
```swift
typealias RequestTransform = (Request) -> (Request)
```
---

```swift
let get: RequestTransform = { request in
  var transformed = request
  transformed.method = .get
  return transformed
}

let post = ...
let put = ...
```

---

[.column]
Me: “Swift lenses”
Google:

[.column]
![](https://townsquare.media/site/204/files/2012/10/Taylor-Glasses.jpg)

---
```swift
let get = methodLens.set(.GET)
let post = methodLens.set(.POST)
let put = methodLens.set(.PUT)
```
---
```swift
func path(_ fragment: CustomStringConvertible) -> RequestTransform {
  pathFragmentLens.set(fragment)
}

let turtlesPath = path("turtles")
```
---
```swift
func idParameter(_ id: UUID) -> RequestTransform {
  path(id)
}
```
---
```swift
func compose(
  _ f: @escaping RequestTransform,
  _ g: @escaping RequestTransform,
  _ h: @escaping RequestTransform
) -> RequestTransform {
  { f(g(h($0))) }
}

func pipe(
  _ f: @escaping RequestTransform,
  _ g: @escaping RequestTransform,
  _ h: @escaping RequestTransform
) -> RequestTransform {
  { h(g(f($0))) }
}
```
---
And since we’re not dealing with generics, we can use variadics to support any number of transforms:

```swift
func pipe(
  _ transforms: RequestTransform...
) -> RequestTransform {
  {
    transforms.reduce($0) { partialRequest, transform in
      transform(partialRequest)
    }
  }
}
```
---
```swift
func getTurtleRequest(with id: UUID) -> RequestTransform {
  pipe(
    get,
    turtlesPath, 
    idParameter(id)
  )
}
```
------

```swift
precedencegroup Group { associativity: left }

infix operator >>>: Group

func >>> <A, B, C>(
  _ lhs: @escaping (A) -> B,
  _ rhs: @escaping (B) -> C) -> (A) -> C {
  return { rhs(lhs($0)) }
}

(get >>> turtlesPath >>> idParameter)(id)
```

---

| Method        | `GET`             | `POST`             | `POST`             |
|---------------|-------------------|--------------------|--------------------|
| Path          | `/turtles/:id`    | `/turtles`         | `/sign-in`         |
| Authenticated | ✅                 | ✅                  | —                  |
| Body          | —                 | `Turtle`           | `Credentials`      |
| Content-Type  | —                 | `application/json` | `application/json` |
| Admin-only    | —                 | ✅                  | —                  |
| Queries       | `?props=name,age` | —                  | —                  |

---

```
(UUID, Token) -> RequestTransform
(Turtle, Token, AdminKey) -> RequestTransform
(Credentials) -> RequestTransform
```

---

We can benefit from encapsulating **recurring configuration steps** and **reusing** them across endpoints. For instance:

- Attaching auth headers.
- Setting an admin-key header.
- Setting method to `POST`  with the correct `Content-Type`.
- etc.

- ---
Let's define a higher order function that allows us to add a single header

```swift
func header(
  key: String,
  value: String
) -> RequestTransform {
  headerLens.set((key, value))
}
```
---
We can then define a function derived from this one that takes a token and add an authentication header:

```swift
func authenticated(
  _ token: String
) -> RequestTransform {
  header(key: "Authentication", value: "Bearer \(token)")
}
```

---
Now we can go back to our `GET` method and add authentication:

```swift
func getTurtleRequest(with id: UUID, and token: String) -> RequestTransform {
  pipe(
    authenticated(token),
    get,
    turtlesPath, 
    idParameter(id)
  )
}
```
---
And we can do the same for query parameters:

```swift
func queryItem(
  key: String,
  value: String
) -> RequestTransform {
  queryParameterLens.set((key, value))
}
```
---

[.column]

| Method        | `GET`             |
|---------------|-------------------|
| Path          | `/turtles/:id`    |
| Authenticated | ✅                 |
| Body          | —                 |
| Content-Type  | —                 |
| Admin-only    | —                 |
| Queries       | `?props=name,age` |

[.column]

```swift
func getTurtleRequest(
  with id: UUID,
  and token: String,
  properties: [String]
) -> RequestTransform {
  pipe(
    authenticated(token),
    get,
    turtlesPath,
    idParameter(id),
    props(properties)
  )
}
```
---
[.column]

| Method        | `POST`             |
|---------------|--------------------|
| Path          | `/turtles`         |
| Authenticated | ✅                  |
| Body          | `Turtle`           |
| Content-Type  | `application/json` |
| Admin-only    | ✅                  |
| Queries       | —                  |

[.column]

```swift
func createTurtleRequest(
  turtle: Turtle,
  and token: String,
  adminKey: String
) -> RequestTransform {
  pipe(
    authenticated(token),
    post,
    turtlesPath,
    adminKeyHeader(adminKey),
    jsonContentType()
  )
}
```

---
[.column]

| Method        | `POST`             |
|---------------|--------------------|
| Path          | `/sign-in`         |
| Authenticated | —                  |
| Body          | `Credentials`      |
| Content-Type  | `application/json` |
| Admin-only    | —                  |
| Queries       | —                  |

[.column]

```swift
func signInRequest(
  creds: Credentials,
) -> RequestTransform {
  pipe(
    post,
    path("sign-in"),
    jsonContentType(),
    body(creds)
  )
}
```

---
## Notice how we’re passing the token with each request via `.authenticated(token)`. That can’t be right.
---

[.code-highlight: 1-3]
[.code-highlight: 7-9]

```swift
send(
  _ request: Request ❌
) async throws -> (Data, URLResponse)

// But instead...

send(
  _ requestTransform: RequestTransform ✅
) async throws -> (Data, URLResponse)
```

---
## This would allow us to _further tweak_ the request by inserting new transforms before applying them.
---
```swift
struct APIClient {
  var token: Token?
  var host: String
  var decoder: JSONDecoder
}
```
---
[.code-highlight: 1-7]
[.code-highlight: 9-14]
[.code-highlight: 12]

```swift
extension APIClient {
  send(
    _ requestTransform: RequestTransform
  ) async throws -> (Data, URLResponse) {
      let request: Request = requestTransform(.init())
      // ...
  }

  sendAuthenticated(
    _ requestTransform: RequestTransform
  ) async throws -> (Data, URLResponse) {
    let authenticated = pipe(requestTransform, authenticated(token))
    send(authenticated)
  }
}

```
---

[.column]

```swift
func getTurtleRequest(
  with id: UUID,
  and token: String,
  properties: [String]
) -> RequestTransform {
  pipe(
    get,
    turtlesPath,
    idParameter(id),
    props(properties)
  )
}
```

[.column]

```swift
func createTurtleRequest(
  turtle: Turtle,
  and token: String,
  adminKey: String
) -> RequestTransform {
  pipe(
    postJSONBody,
    turtlesPath,
    adminKeyHeader(adminKey)
  )
}
```

---
```swift
let identity: RequestTransform = { $0 }

pipe(
  get,
  asAdmin ? adminKeyHeader(adminKey) : identity
)
```
---
Some transform samples from a handful of production codebases:

* `cachePolicy`
* `timeOutInterval`
* `apiKeyheader`
* `paginationQueries`

---

## This approach is powerful since defining new behavior (transforms) can be done _on-the-fly_ and _in-place_—perfect when working with _highly composable APIs_.

---

### It allows us to _expand the API surface_ without resorting to protocols, subclassing, or generics.

### It also leaves the door open to customization on a case-by-case basis. This includes _handling special cases_, _testing / mocking_, etc.

---

[.column]

We only used **pure functions**[^4] , which come with the following benefits:

* Safer and more predictable.
* Easier to test and mock.
* More composable as the complexity or need grow.

[.column]
![Fill](https://img.brickowl.com/files/image_cache/larger/lego-minecraft-turtle-3.jpg)

[^4]: A function is pure when it produces no side-effects.

---
### Areas where function composition can be used:

* Builder pattern (Factories)
* Configuration (network requests, URL paths, etc.),
* 2D drawing primitives (canvas, Quartz, etc.),
* App state management (unidirectional data flows such as TCA, Elm, Flux, etc.),
* Styling user interfaces (value types).

---
# Thank you! 

![Fill](https://c.tenor.com/9n8o72_THvkAAAAC/funny-animals-cute-animals.gif)

You can find the `RESTClient` on GitHub: `kaishin/RESTClient`

### Questions?