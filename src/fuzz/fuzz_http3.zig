const std = @import("std");
const Http3 = @import("../http3.zig");

pub fn main() !void {
    std.debug.print("Starting HTTP/3 fuzz testing...\n", .{});

    var buffer: [256]u8 = undefined;
    std.crypto.random.bytes(&buffer);

    // Attempt to decode a random malformed HTTP/3 frame
    std.debug.print("Fuzzing HTTP/3 frame decoding...\n", .{});
    _ = Http3.Http3Frame.decode(&buffer) catch |err| {
        std.debug.print("Handled malformed HTTP/3 frame: {}\n", .{err});
    };

    // Create a random frame and attempt to encode it
    std.debug.print("Fuzzing HTTP/3 frame encoding...\n", .{});
    var frame = Http3.Http3Frame{
        .frame_type = @enumFromInt(buffer[0] % 5), // Random frame type (bounded)
        .payload = buffer[1..], // Use remaining bytes as payload
    };

    var encoded_buffer: [256]u8 = undefined;
    frame.encode(&encoded_buffer) catch |err| {
        std.debug.print("Handled encoding failure: {}\n", .{err});
    };

    std.debug.print("HTTP/3 fuzz test completed.\n", .{});
}
