const std = @import("std");
const Connection = @import("../transport/connection.zig");
const Http3 = @import("../http3.zig");

pub export fn quic_connect() ?*Connection.Connection {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const connection = Connection.init(allocator) catch return null;
    return connection;
}

pub export fn quic_send_request(conn: *Connection.Connection, method: [*]const u8, path: [*]const u8) bool {
    const allocator = std.heap.page_allocator;

    var stream = Http3.Http3Stream.init(allocator, 1) catch return false;
    defer stream.close();

    var request_buffer: [256]u8 = undefined;
    const request_string = std.fmt.bufPrint(&request_buffer, "{s} {s} HTTP/3", .{ method, path }) catch return false;

    const request = Http3.Http3Frame{
        .frame_type = Http3.Http3FrameType.Headers,
        .payload = request_string,
    };

    if (conn.send(&request_buffer[0..request_string.len]) catch return false) {
        return stream.send_frame(request) == null;
    }

    return false;
}

pub export fn quic_receive_response(conn: *Connection.Connection, buffer: [*]u8, buffer_size: usize) usize {
    const allocator = std.heap.page_allocator;

    var stream = Http3.Http3Stream.init(allocator, 1) catch return 0;
    defer stream.close();

    const response = stream.receive_frame() catch return 0;

    const length = @min(response.payload.len, buffer_size);
    @memcpy(buffer[0..length], response.payload[0..length]);

    // Ensure the connection is referenced (fixing the unused parameter warning)
    _ = conn; // Explicitly mark conn as used

    return length;
}

pub export fn quic_close(conn: *Connection.Connection) void {
    conn.close();
}
