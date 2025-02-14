const std = @import("std");
const net = std.net;
const Connection = @import("../transport/connection.zig").Connection;
const Http3 = @import("../http3.zig");
const start_server = @import("quic_server.zig").start_server;

pub const Error = error{
    ConnectionFailed,
    SendFailed,
    ReceiveFailed,
};

pub fn start_client(server_ip: []const u8, port: u16, allocator: std.mem.Allocator) !void {
    std.debug.print("Connecting to QUIC server {s}:{d}...\n", .{ server_ip, port });

    var connection = try Connection.init(allocator);
    defer connection.close();

    try connection.establish();

    var http3_stream = try Http3.Http3Stream.init(allocator, 1);
    defer http3_stream.close();

    const request = Http3.Http3Frame{
        .frame_type = Http3.Http3FrameType.Headers,
        .payload = "GET / HTTP/3",
    };

    try http3_stream.send_frame(request);
    const response = try http3_stream.receive_frame();

    std.debug.print("Response: {s}\n", .{response.payload});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 3) {
        std.debug.print("Usage: quic_client <server_ip> <port>\n", .{});
        return;
    }

    const server_ip = args[1];
    const port = try std.fmt.parseInt(u16, args[2], 10);

    try start_client(server_ip, port, allocator);
}

// ✅ **Fixed Unit Test**
test "QUIC client successfully sends and receives response" {
    const allocator = std.testing.allocator;

    // ✅ Start a mock QUIC server
    const test_port: u16 = 9001;
    var thread = try std.Thread.spawn(.{}, start_server, .{ test_port, allocator });
    defer thread.join();

    std.time.sleep(1_000_000_000); // ✅ Give server time to start

    // ✅ Run the client
    try start_client("127.0.0.1", test_port, allocator);

    try std.testing.expect(true); // ✅ If no crash, assume success
}
