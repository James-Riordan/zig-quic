const std = @import("std");
const testing = std.testing;
const Connection = @import("../../transport/connection.zig");
const Http3 = @import("../../http3.zig");

test "End-to-end QUIC client-server exchange" {
    const allocator = testing.allocator;

    // Simulate server setup
    var server_connection = try Connection.init(allocator);
    defer server_connection.close();
    try server_connection.establish();

    var server_stream = try Http3.Http3Stream.init(allocator, 1);
    defer server_stream.close();

    // Simulate client setup
    var client_connection = try Connection.init(allocator);
    defer client_connection.close();
    try client_connection.establish();

    var client_stream = try Http3.Http3Stream.init(allocator, 1);
    defer client_stream.close();

    // Client sends an HTTP/3 request
    const request = Http3.Http3Frame{
        .frame_type = Http3.Http3FrameType.Headers,
        .payload = "GET / HTTP/3",
    };

    try client_stream.send_frame(request);

    // Server receives the request
    const received_request = try server_stream.receive_frame();
    try testing.expectEqual(request.frame_type, received_request.frame_type);
    try testing.expectEqualSlices(u8, request.payload, received_request.payload);

    // Server sends a response
    const response = Http3.Http3Frame{
        .frame_type = Http3.Http3FrameType.Data,
        .payload = "HTTP/3 200 OK\nContent-Length: 13\n\nHello, QUIC!",
    };

    try server_stream.send_frame(response);

    // Client receives the response
    const received_response = try client_stream.receive_frame();
    try testing.expectEqual(response.frame_type, received_response.frame_type);
    try testing.expectEqualSlices(u8, response.payload, received_response.payload);
}
