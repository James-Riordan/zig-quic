const std = @import("std");
const Connection = @import("../transport/connection.zig");
const Packet = @import("../transport/packet.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    std.debug.print("Starting QUIC transport fuzz testing...\n", .{});

    var connection = try Connection.init(allocator);
    defer connection.close();
    try connection.establish();

    var buffer: [256]u8 = undefined;
    std.crypto.random.bytes(&buffer);

    // Attempt to decode a random malformed packet
    std.debug.print("Fuzzing QUIC packet decoding...\n", .{});
    _ = Packet.decode(&buffer) catch |err| {
        std.debug.print("Handled malformed packet: {}\n", .{err});
    };

    // Attempt to send a malformed packet
    std.debug.print("Fuzzing QUIC packet sending...\n", .{});
    connection.send(&buffer) catch |err| {
        std.debug.print("Handled unexpected transport send error: {}\n", .{err});
    };

    // Randomly switch connection states
    std.debug.print("Fuzzing unexpected state transitions...\n", .{});
    connection.state = @enumFromInt(buffer[0] % 5); // Assigns a random invalid state

    std.debug.print("QUIC transport fuzz test completed.\n", .{});
}
