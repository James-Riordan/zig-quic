const std = @import("std");

// ✅ Expose transport module (fixes integration test imports)
pub const transport = struct {
    pub const congestion = @import("transport/congestion.zig");
    pub const connection = @import("transport/connection.zig");
    pub const packet = @import("transport/packet.zig");
    pub const stream = @import("transport/stream.zig");
};

// ✅ Expose core QUIC logic
pub const quic = @import("quic.zig");

// ✅ Expose HTTP/3 module
pub const http3 = @import("http3.zig");

// ✅ Expose CLI modules
pub const cli = struct {
    pub const client = @import("cli/quic_client.zig");
    pub const server = @import("cli/quic_server.zig");
};

// ✅ Main function to select between client/server
pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: zig-quic <client|server> [...args]\n", .{});
        return;
    }

    if (std.mem.eql(u8, args[1], "client")) {
        try cli.client.main();
    } else if (std.mem.eql(u8, args[1], "server")) {
        try cli.server.main();
    } else {
        std.debug.print("Invalid argument. Use 'client' or 'server'.\n", .{});
    }
}
