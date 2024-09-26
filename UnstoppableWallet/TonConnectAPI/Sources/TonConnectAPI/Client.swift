// Generated by swift-openapi-generator, do not modify.
@_spi(Generated) import OpenAPIRuntime
#if os(Linux)
@preconcurrency import struct Foundation.URL
@preconcurrency import struct Foundation.Data
@preconcurrency import struct Foundation.Date
#else
import struct Foundation.URL
import struct Foundation.Data
import struct Foundation.Date
#endif
import HTTPTypes
public struct Client: APIProtocol {
    /// The underlying HTTP client.
    private let client: UniversalClient
    /// Creates a new client.
    /// - Parameters:
    ///   - serverURL: The server URL that the client connects to. Any server
    ///   URLs defined in the OpenAPI document are available as static methods
    ///   on the ``Servers`` type.
    ///   - configuration: A set of configuration values for the client.
    ///   - transport: A transport that performs HTTP operations.
    ///   - middlewares: A list of middlewares to call before the transport.
    public init(
        serverURL: Foundation.URL,
        configuration: Configuration = .init(),
        transport: any ClientTransport,
        middlewares: [any ClientMiddleware] = []
    ) {
        self.client = .init(
            serverURL: serverURL,
            configuration: configuration,
            transport: transport,
            middlewares: middlewares
        )
    }
    private var converter: Converter { client.converter }
    /// - Remark: HTTP `GET /events`.
    /// - Remark: Generated from `#/paths//events/get(events)`.
    public func events(_ input: Operations.events.Input) async throws -> Operations.events.Output {
        try await client.send(
            input: input,
            forOperation: Operations.events.id,
            serializer: { input in
                let path = try converter.renderedPath(template: "/events", parameters: [])
                var request: HTTPTypes.HTTPRequest = .init(soar_path: path, method: .get)
                suppressMutabilityWarning(&request)
                try converter.setQueryItemAsURI(
                    in: &request,
                    style: .form,
                    explode: true,
                    name: "client_id",
                    value: input.query.client_id
                )
                try converter.setQueryItemAsURI(
                    in: &request,
                    style: .form,
                    explode: true,
                    name: "last_event_id",
                    value: input.query.last_event_id
                )
                converter.setAcceptHeader(in: &request.headerFields, contentTypes: input.headers.accept)
                return (request, nil)
            },
            deserializer: { response, responseBody in
                switch response.status.code {
                case 200:
                    let contentType = converter.extractContentTypeIfPresent(in: response.headerFields)
                    let body: Operations.events.Output.Ok.Body
                    if try contentType == nil
                        || converter.isMatchingContentType(received: contentType, expectedRaw: "text/event-stream")
                    {
                        body = try converter.getResponseBodyAsBinary(
                            OpenAPIRuntime.HTTPBody.self,
                            from: responseBody,
                            transforming: { value in .text_event_hyphen_stream(value) }
                        )
                    } else {
                        throw converter.makeUnexpectedContentTypeError(contentType: contentType)
                    }
                    return .ok(.init(body: body))
                default: return .undocumented(statusCode: response.status.code, .init())
                }
            }
        )
    }
    /// - Remark: HTTP `POST /message`.
    /// - Remark: Generated from `#/paths//message/post(message)`.
    public func message(_ input: Operations.message.Input) async throws -> Operations.message.Output {
        try await client.send(
            input: input,
            forOperation: Operations.message.id,
            serializer: { input in
                let path = try converter.renderedPath(template: "/message", parameters: [])
                var request: HTTPTypes.HTTPRequest = .init(soar_path: path, method: .post)
                suppressMutabilityWarning(&request)
                try converter.setQueryItemAsURI(
                    in: &request,
                    style: .form,
                    explode: true,
                    name: "client_id",
                    value: input.query.client_id
                )
                try converter.setQueryItemAsURI(
                    in: &request,
                    style: .form,
                    explode: true,
                    name: "to",
                    value: input.query.to
                )
                try converter.setQueryItemAsURI(
                    in: &request,
                    style: .form,
                    explode: true,
                    name: "ttl",
                    value: input.query.ttl
                )
                converter.setAcceptHeader(in: &request.headerFields, contentTypes: input.headers.accept)
                let body: OpenAPIRuntime.HTTPBody?
                switch input.body {
                case let .plainText(value):
                    body = try converter.setRequiredRequestBodyAsBinary(
                        value,
                        headerFields: &request.headerFields,
                        contentType: "text/plain"
                    )
                }
                return (request, body)
            },
            deserializer: { response, responseBody in
                switch response.status.code {
                case 200:
                    let contentType = converter.extractContentTypeIfPresent(in: response.headerFields)
                    let body: Components.Responses.Response.Body
                    if try contentType == nil
                        || converter.isMatchingContentType(received: contentType, expectedRaw: "application/json")
                    {
                        body = try await converter.getResponseBodyAsJSON(
                            Components.Responses.Response.Body.jsonPayload.self,
                            from: responseBody,
                            transforming: { value in .json(value) }
                        )
                    } else {
                        throw converter.makeUnexpectedContentTypeError(contentType: contentType)
                    }
                    return .ok(.init(body: body))
                default:
                    let contentType = converter.extractContentTypeIfPresent(in: response.headerFields)
                    let body: Components.Responses.Response.Body
                    if try contentType == nil
                        || converter.isMatchingContentType(received: contentType, expectedRaw: "application/json")
                    {
                        body = try await converter.getResponseBodyAsJSON(
                            Components.Responses.Response.Body.jsonPayload.self,
                            from: responseBody,
                            transforming: { value in .json(value) }
                        )
                    } else {
                        throw converter.makeUnexpectedContentTypeError(contentType: contentType)
                    }
                    return .`default`(statusCode: response.status.code, .init(body: body))
                }
            }
        )
    }
}
