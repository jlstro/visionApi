// Sources/VisionOCR/Controllers/OCRController.swift

import Vapor
import Vision
import Quartz      // for ImageIO
import CoreImage   // for CIImage

struct OCRResponse: Content {
    let success: Bool
    let text: String
}

struct FileUpload: Content {
    var file: File
    var language: String?   // e.g. "ar" or "en", defaults to en
}

final class OCRController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let ocr = routes.grouped("ocr")
        ocr.post(use: recognize)                 // POST /ocr (multipart)
        ocr.post("path", use: recognizeFromPath) // POST /ocr/path (JSON)
    }

    // MARK: - Multipart file upload

func recognize(req: Request) async throws -> OCRResponse {
    // 1) Decode multipart form with a `file: File` and optional `language`
    let upload = try req.content.decode(FileUpload.self)
    let buffer = upload.file.data
    let data   = Data(buffer: buffer)
    let lang   = upload.language ?? "ar"   // default to Arabic

    // 2) Convert Data → CIImage
    guard let ciImage = CIImage(data: data) else {
        throw Abort(.badRequest, reason: "Invalid image data")
    }
    // 3) Render to CGImage
    let cgImage = try render(ciImage: ciImage)

    // 4) Build and configure the Vision request
    let visionReq = VNRecognizeTextRequest()
    visionReq.recognitionLevel       = .accurate
    visionReq.usesLanguageCorrection = true
    visionReq.recognitionLanguages   = [lang]

    // 5) Perform the OCR
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    try handler.perform([visionReq])

    // 6) Collect recognized lines
    let observations = visionReq.results as? [VNRecognizedTextObservation] ?? []
    let lines = observations.compactMap { obs in
        obs.topCandidates(1).first?.string
    }

    return OCRResponse(success: true, text: lines.joined(separator: "\n"))
}


    // MARK: - Path‐based upload

    struct PathPayload: Content {
        let path: String
    }

    func recognizeFromPath(req: Request) async throws -> OCRResponse {
        let payload = try req.content.decode(PathPayload.self)
        let url     = URL(fileURLWithPath: payload.path)
        let data    = try Data(contentsOf: url)

        guard let ciImage = CIImage(data: data) else {
            throw Abort(.badRequest, reason: "Cannot load or decode image at path")
        }
        let cgImage = try render(ciImage: ciImage)
        let text    = try await runVision(on: cgImage)
        return OCRResponse(success: true, text: text)
    }

    // MARK: - Helpers

    /// Renders a CIImage into a CGImage
    private func render(ciImage: CIImage) throws -> CGImage {
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            throw Abort(.internalServerError, reason: "Failed to create CGImage")
        }
        return cgImage
    }

    /// Performs the Vision text-recognition request
    private func runVision(on cgImage: CGImage) async throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel       = .accurate
        request.recognitionLanguages   = ["ar"]
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        let observations = request.results as? [VNRecognizedTextObservation] ?? []
        let lines = observations.compactMap { obs in
            obs.topCandidates(1).first?.string
        }
        return lines.joined(separator: "\n")
    }
}
