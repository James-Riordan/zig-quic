const std = @import("std");
const net = std.net;
const Connection = @import("../transport/connection.zig");
const Http3 = @import("../http3.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const port: u16 = 4433; // Default QUIC port
    var server_socket = try net.UDP.init();
    defer server_socket.deinit();

    const address = try net.Address.parseIp4("0.0.0.0", port);
    try server_socket.bind(address);

    std.debug.print("Minimal QUIC server listening on port {}...\n", .{port});

    var buffer: [2048]u8 = undefined;
    var sender_addr: net.Address = undefined;

    const received_bytes = server_socket.receiveFrom(&buffer, &sender_addr) catch |err| {
        std.debug.print("Error receiving data: {}\n", .{err});
        return;
    };

    std.debug.print("Connection received from {}:{}\n", .{ sender_addr, port });

    var connection = try Connection.init(allocator);
    defer connection.close();
    try connection.establish();

    var http3_stream = try Http3.Http3Stream.init(allocator, 1);
    defer http3_stream.close();

    const request = try Http3.Http3Frame.decode(buffer[0..received_bytes]);
    std.debug.print("Received request: {s}\n", .{request.payload});

    const response = Http3.Http3Frame{
        .frame_type = Http3.Http3FrameType.Data,
        .payload = "HTTP/3 200 OK\nContent-Length: 13\n\nHello, QUIC!",
    };

    try http3_stream.send_frame(response);
    std.debug.print("Minimal server response sent.\n", .{});
}
