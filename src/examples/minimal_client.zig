const std = @import("std");
const net = @import("std").net;
const Connection = @import("../transport/connection.zig");
const Http3 = @import("../http3.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const server_ip = "127.0.0.1"; // Change this if connecting to a remote server
    const port: u16 = 4433;

    std.debug.print("Connecting to QUIC server at {}:{}...\n", .{ server_ip, port });

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
    std.debug.print("Request sent to server.\n", .{});

    const response = try http3_stream.receive_frame();
    std.debug.print("Received response: {s}\n", .{response.payload});
}
