footer: CocoaHeads Stockholm – April 2022
# The Power of Function Composition in Swift
### By Reda Lemeden

---
## Mandatory slide about myself.
![Fill](https://redalemeden.com/social-cards/default.jpg)

- SwiftUI / TCA / Server-side Swift
- redalemeden.com
- @kaishin
- I like turtles 🐢

---

## Does anyone here have _Chelonaphobia_? [^1]

[^1]: Fear of turtles.

---
## Ground Rules

* *No* custom operators.
* *No* metasyntactic variables (foo, bar, baz, etc.)
* *No* mathematical notations.
* Lots of code.
* Turtles.

---
## [Fit] Let’s get going!

![Fill](https://c.tenor.com/c5nS7cjT5ZAAAAAC/turtle-dog.gif)
![Fill](https://c.tenor.com/c5nS7cjT5ZAAAAAC/turtle-dog.gif)
![Fill](https://c.tenor.com/c5nS7cjT5ZAAAAAC/turtle-dog.gif)

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
## [Fit] Every function has a type.
---

More commonly referred to as a function’s “signature.”

## `Parameter Types -> Return Type` 

---
## Examples

```swift
func graze() {} 
let graze = {}
// () -> Void

func add(_ lhs: Int, rhs: Int) -> Int { lhs + rhs } 
// (Int, Int) -> Int
```

---
# First-class Functions
Functions in Swift support _all the standard operations_ available to other types.

---
## Functions as Values
---

[.code-highlight: 1]
[.code-highlight: 3-5]
[.code-highlight: 7-8]

```swift
func add(_ lhs: Int, rhs: Int) -> Int { lhs + rhs } 

let doMath: (Int, Int) -> Int
doMath = add
doMath = { $0 - $1 } // ❌

var doMath = add
doMath = { $0 - $1 } 
```
---
## Functions as Parameters
---
[.code-highlight: 1]
[.code-highlight: 1-5]
[.code-highlight: all]

```swift
let graze = {}

func doSomething(_ action: () -> Void) {
  action()
}

doSomething(graze)
```
---
## `doSomething` is a called a _higher-order function_.
---
## Functions as Return Values
---

[.code-highlight: 1-5]
[.code-highlight: 1-5, 7-8]
[.code-highlight: 1-5, 10-11]
[.code-highlight: 1-5, 13-14]

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
## `drop(:)` is another flavor of _higher-order functions_.
---
## Higher-order functions open the door to _point-free function composition_.

---
### Function composition is a series of functions where each function:

1. receives input, 
2. does some additional computation, 
3. then hands over the output to the next function in the pipe.

---
## Example
```swift
drop10Last(drop2Last(dropLast("The slow green turtle jumps...not")))

func drop13Last(_ value: String) -> String {
  drop10Last(drop2Last(dropLast(value)))
}
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

### Step 1

Create a client-side representation of a given API endpoint.

* Input data to be sent with the request.
* Output to expect from the response.

---

### Step 2

Add logic to transform input data into a request abstraction (`URLRequest` or similar).

* Place the right data, in the right format, at the right placement in the request (headers, body, parameters, etc).

---
### Step 3

Add logic to pass the request, alongside any response expectations, to the networking layer.

### Step 4

Add logic to decode the response data into the expected output types.

---

### Step 1: Create a client-side representation of the endpoint.

The simplest conceptual representation:

`(Input) -> Output`

---

### Example

An endpoint that takes a `UUID` and returns a `Turtle` can be represented as an `async` function of the following signature:

```swift
func getTurtle(with id: UUID) async throws -> Turtle {
  // ...
}

// Or...

enum API {
  case getTurtle(id: UUID, response: Turtle)
}
```


---
### Step 2: Transform input into a request abstraction [^2]

[^2]: We can use the built-in `URLRequest`—or define another, more type-safe, abstraction on top of it.

---

```swift
struct Request {
  var method: HTTPMethod
  var path: URLPath
  var queryItems: [String: String]
  var headers: [String: String]
  var body: Data?
}
```
---
```swift
public struct URLPath {
  public var fragments: [CustomStringConvertible]
  public init(stringLiteral value: String) {}
}

enum HTTPMethod: String {
  case get = "GET"
  // ...
}
```

---
## `(Input) -> Request`
---
## `(UUID) -> Request` [^3]

[^3]: In the context of this REST resource.

---
```swift
func getTurtleRequest(with id: UUID) -> Request

// Or...

extension Request {
  getTurtle(with id: UUID) -> Self {}
}
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
The Semi-Declarative Approach

```swift
func getTurtleRequest(with id: UUID) -> Request {
  get(path("turtles/\(id)"))(.init())
}
```

---
The Declarative Approach

```swift
func getTurtleRequest(with id: UUID) -> RequestTransform {
  magic(
    get,
    turtlesPath, 
    idParameter(id)
  )
}
```

---
### So how can we achieve this?

---
# 💡 Request Transforms 💡

---
## `(Request) -> (Request)`

---
```swift
typealias RequestTransform = (Request) -> (Request)

let identity: RequestTransform = { $0 }

let get: RequestTransform = { request in
  var transformed = request
  transformed.method = .get
  return transformed
}

let post = ...
let put = ...
```
---
```swift
func path(_ fragment: CustomStringConvertible) -> RequestTransform {
  { request in
    var transformed = request
    transformed.path.fragments.append(fragment)
    return transformed
  }
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
We have:

* `get`
* `turtlesPath`
* `idParameter`

### How do we define `magic()` such as…
## `magic(get, turtlesPath, idParameter(someID))` 
### is of type 👉 `RequestTransform` 👈?

---
```swift
func magic(
  _ f: @escaping RequestTransform,
  _ g: @escaping RequestTransform,
  _ h: @escaping RequestTransform
) -> RequestTransform {
  /* ... */
}
```
---
```swift
func magic(
  _ f: @escaping RequestTransform,
  _ g: @escaping RequestTransform,
  _ h: @escaping RequestTransform
) -> RequestTransform {
  { /* ... */ }
}
```
---
```swift
func magic(
  _ f: @escaping RequestTransform,
  _ g: @escaping RequestTransform,
  _ h: @escaping RequestTransform
) -> RequestTransform {
  { h(g(f($0))) }
}
```
---
##  `f(g(h($0)))` ▶ Compose (RTL) 
## `h(g(f($0)))`  ▶ Pipe (LTR)

---
[.code-highlight: 1]

```swift
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
---
## But what do we gain?
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
### Some of the configuration steps we will be repeating more than once:
[.code-highlight: all]
[.code-highlight: 4,12]
```swift
var request = Request()

request.headers = ["Authentication": "Bearer token"]
request.headers = ["Content-Type": "application/json"]
request.method = .post
request.body = ...
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
  { request in
    var newRequest = request
    newRequest.headers[key] = value
    return newRequest
  }
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
  { request in
    var newRequest = request
    newRequest.queryItems[key] = value
    return newRequest
  }
}
```
---
If we’re going to reuse props in other endpoints we might as well create a transform for that:

```swift
func props(
  _ properties: [String]
) -> RequestTransform {
  queryItem(key: "props", value: properties.joined(separator: ","))
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
Typically `send` methods take the following form:

```swift
send(
  _ request: Request
) async throws -> (Data, URLResponse)
```
---
But what if we delay request creation until the last step of the pipeline?

[.code-highlight: 2]

```swift
send(
  _ requestTransform: RequestTransform
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

Last but not least, remember the `identity` transform?
It comes handy when doing conditional composition

```swift
compose(
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
* Styling user interfaces.

---
## Some Caveats
* To make these APIs truly point-free, we need to introduce generics, which locks us out from using variadic parameters.
* Over-relying on type inference can cause code written in this style to be quite unreadable.
* This approach is not suitable for reference types.
	* Need to create bridge value types.

---

![Fill](https://c.tenor.com/iS6Ts_Y2g7cAAAAC/climbing-up-world-turtle-day.gif)

---

### You can find the `RESTClient` on GitHub: `kaishin/RESTClient`

The slides will be linked to from the README as well.

---
## [Fit] Thank you! 

![Fill](https://c.tenor.com/9n8o72_THvkAAAAC/funny-animals-cute-animals.gif)

---
## [Fit] Questions

![Fill](https://c.tenor.com/9n8o72_THvkAAAAC/funny-animals-cute-animals.gif)

---