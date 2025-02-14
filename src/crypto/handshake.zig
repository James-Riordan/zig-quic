const std = @import("std");
const Tls = @import("tls.zig");
const Packet = @import("../transport/packet.zig");

pub const Error = error{
    HandshakeFailed,
    InvalidTransportParams,
};

pub const QuicHandshake = struct {
    allocator: std.mem.Allocator,
    tls: Tls.QuicTLS,
    handshake_complete: bool,

    pub fn init(allocator: std.mem.Allocator) !QuicHandshake {
        return QuicHandshake{
            .allocator = allocator,
            .tls = try Tls.QuicTLS.init(allocator),
            .handshake_complete = false,
        };
    }

    pub fn perform_handshake(self: *QuicHandshake, client_hello: []const u8) !void {
        try self.tls.handshake(client_hello);

        // Simulate QUIC transport parameter validation
        if (client_hello.len < 64) return Error.InvalidTransportParams;

        self.handshake_complete = true;
    }
};

// ✅ **Embedded Unit Tests**
test "QUIC handshake success" {
    const allocator = std.testing.allocator;
    var handshake = try QuicHandshake.init(allocator);

    var client_hello: [64]u8 = undefined;
    std.crypto.random.bytes(&client_hello);

    try handshake.perform_handshake(&client_hello);
    try std.testing.expect(handshake.handshake_complete);
}
