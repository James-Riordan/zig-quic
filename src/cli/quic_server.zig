const std = @import("std");
const posix = std.posix;
const Connection = @import("../transport/connection.zig").Connection;
const Http3 = @import("../http3.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: quic_server <port>\n", .{});
        return;
    }

    const port = try std.fmt.parseInt(u16, args[1], 10);

    // ✅ Create a UDP socket using POSIX
    const sockfd = try posix.socket(posix.AF.INET, posix.SOCK.DGRAM, posix.IPPROTO.UDP);
    defer _ = posix.close(sockfd);

    // ✅ Set socket address (IPv4)
    var addr = posix.sockaddr.in{
        .family = posix.AF.INET,
        .port = std.mem.nativeToBig(u16, port),
        .addr = 0, // INADDR_ANY (bind to all interfaces)
        .zero = [_]u8{0} ** 8,
    };

    try posix.bind(sockfd, @ptrCast(&addr), @sizeOf(posix.sockaddr.in));

    std.debug.print("QUIC server listening on port {}...\n", .{port});

    var buffer: [2048]u8 = undefined;

    while (true) {
        var sender_addr: posix.sockaddr.in = undefined;
        var addr_len: posix.socklen_t = @sizeOf(posix.sockaddr.in);

        // ✅ Receive UDP data
        const received_bytes = posix.recvfrom(
            sockfd,
            &buffer,
            0,
            @ptrCast(&sender_addr),
            &addr_len,
        ) catch |err| {
            std.debug.print("Error receiving data: {}\n", .{err});
            continue;
        };

        const sender_ip = std.mem.toBytes(sender_addr.addr);
        const sender_port = std.mem.bigToNative(u16, sender_addr.port);

        std.debug.print("Received {} bytes from {}.{}.{}.{}:{}\n", .{
            received_bytes,
            sender_ip[0],
            sender_ip[1],
            sender_ip[2],
            sender_ip[3],
            sender_port,
        });

        // ✅ Initialize QUIC connection
        var connection = try Connection.init(allocator);
        defer connection.close();
        try connection.establish();

        // ✅ Initialize HTTP/3 stream
        var http3_stream = try Http3.Http3Stream.init(allocator, 1);
        defer http3_stream.close();

        // ✅ Decode HTTP/3 frame
        const request = Http3.Http3Frame.decode(buffer[0..received_bytes]) catch |err| {
            std.debug.print("Invalid HTTP/3 frame received: {}\n", .{err});
            continue;
        };

        std.debug.print("Received request: {s}\n", .{request.payload});

        // ✅ Prepare HTTP/3 response
        const response = Http3.Http3Frame{
            .frame_type = Http3.Http3FrameType.Data,
            .payload = "HTTP/3 200 OK\nContent-Length: 13\n\nHello, QUIC!",
        };

        try http3_stream.send_frame(response);
        std.debug.print("Response sent to {}.{}.{}.{}:{}\n", .{ sender_ip[0], sender_ip[1], sender_ip[2], sender_ip[3], sender_port });

        // ✅ Encode and send HTTP/3 response
        const response_encoded = try response.encode(&buffer);
        _ = try posix.sendto(
            sockfd,
            buffer[0..response_encoded],
            0,
            @ptrCast(&sender_addr),
            addr_len,
        );
    }
}
