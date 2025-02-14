const std = @import("std");
const testing = std.testing;
const Connection = @import("zig_quic").transport.connection.Connection;
const Http3 = @import("zig_quic").http3;

test "End-to-end QUIC client-server exchange" {
    const allocator = testing.allocator;

    // ✅ Simulate server setup
    var server_connection = try Connection.init(allocator);
    defer server_connection.close();
    try server_connection.establish();

    var server_stream = try Http3.Http3Stream.init(allocator, 1);
    defer server_stream.close();

    // ✅ Simulate client setup
    var client_connection = try Connection.init(allocator);
    defer client_connection.close();
    try client_connection.establish();

    var client_stream = try Http3.Http3Stream.init(allocator, 1);
    defer client_stream.close();

    // ✅ Client sends an HTTP/3 request
    std.debug.print("Client: Sending HTTP/3 request...\n", .{});
    const request = Http3.Http3Frame{
        .frame_type = Http3.Http3FrameType.Headers,
        .payload = "GET / HTTP/3",
    };

    try client_stream.send_frame(request);
    try client_stream.flush(&server_stream); // ✅ Flush client → server

    std.time.sleep(100_000_000); // 🔥 100ms delay to ensure flush() completes

    // ✅ Server receives the request
    std.debug.print("Server: Receiving HTTP/3 request...\n", .{});
    const received_request = server_stream.receive_frame() catch |err| {
        std.debug.print("Error: Failed to receive frame: {}\n", .{err});
        return err;
    };

    defer allocator.free(received_request.payload); // ✅ Free `received_request.payload` here

    std.debug.print("Server received: {s}\n", .{received_request.payload});
    try testing.expectEqual(request.frame_type, received_request.frame_type);
    try testing.expectEqualSlices(u8, request.payload, received_request.payload);

    // ✅ Server sends a response
    std.debug.print("Server: Sending HTTP/3 response...\n", .{});
    const response = Http3.Http3Frame{
        .frame_type = Http3.Http3FrameType.Data,
        .payload = "HTTP/3 200 OK\nContent-Length: 13\n\nHello, QUIC!",
    };

    try server_stream.send_frame(response);
    try server_stream.flush(&client_stream); // ✅ Flush server → client

    std.time.sleep(100_000_000); // 🔥 100ms delay to ensure flush() completes

    // ✅ Client receives the response
    std.debug.print("Client: Receiving HTTP/3 response...\n", .{});
    const received_response = client_stream.receive_frame() catch |err| {
        std.debug.print("Error: Failed to receive response: {}\n", .{err});
        return err;
    };

    defer allocator.free(received_response.payload); // ✅ Free `received_response.payload` here

    std.debug.print("Client received: {s}\n", .{received_response.payload});
    try testing.expectEqual(response.frame_type, received_response.frame_type);
    try testing.expectEqualSlices(u8, response.payload, received_response.payload);
}
