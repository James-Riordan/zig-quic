const std = @import("std");
const quic_client = @import("cli/quic_client.zig");
const quic_server = @import("cli/quic_server.zig");

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: zig-quic <client|server> [...args]\n", .{});
        return;
    }

    if (std.mem.eql(u8, args[1], "client")) {
        try quic_client.main();
    } else if (std.mem.eql(u8, args[1], "server")) {
        try quic_server.main();
    } else {
        std.debug.print("Invalid argument. Use 'client' or 'server'.\n", .{});
    }
}
