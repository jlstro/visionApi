import Vapor

// func routes(_ app: Application) throws {
//     app.get { req async in
//         "It works!"
//     }

//     app.get("hello") { req async -> String in
//         "Hello, world!"
//     }
// }



func routes(_ app: Application) throws {
    // Simple health check
    app.get("health") { _ in
        return HTTPStatus.ok
    }

    // Your existing OCR routes
    try app.register(collection: OCRController())
}


func routes(_ app: Application) throws {
    try app.register(collection: OCRController())
}