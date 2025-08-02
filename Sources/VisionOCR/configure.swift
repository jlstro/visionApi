import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // max payload size
    app.routes.defaultMaxBodySize = ByteCount(value: 50 * 1024 * 1024)

    // register routes
    try routes(app)
}
