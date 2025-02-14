const std = @import("std");
const net = std.net;
const Connection = @import("../transport/connection.zig").Connection;
const Http3 = @import("../http3.zig");

pub const Error = error{
    ConnectionFailed,
    SendFailed,
    ReceiveFailed,
};

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

    std.debug.print("Connecting to QUIC server {d}:{d}...\n", .{ server_ip, port });

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
