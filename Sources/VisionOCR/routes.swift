import Vapor

func routes(_ app: Application) throws {
    // 1) Health endpoint
    app.get("health") { _ in
        return HTTPStatus.ok
    }

    // 2) OCR endpoints
    try app.register(collection: OCRController())
}
