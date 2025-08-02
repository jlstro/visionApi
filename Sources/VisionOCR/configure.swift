import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    app.http.server.configuration.hostname = "0.0.0.0" // bind to make reachable in LAN
    app.http.server.configuration.port     = 8080

    // max payload size
    app.routes.defaultMaxBodySize = ByteCount(value: 50 * 1024 * 1024)

    // register routes
    try routes(app)
}
