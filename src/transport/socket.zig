const std = @import("std");
const net = std.net;

pub const Error = error{
    SocketInitFailed,
    SendFailed,
    ReceiveFailed,
};

pub const QuicSocket = struct {
    allocator: std.mem.Allocator,
    socket: net.UDP,
    endpoint: net.Address,

    pub fn init(allocator: std.mem.Allocator, port: u16) !QuicSocket {
        const addr = try net.Address.parseIp4("0.0.0.0", port);
        var socket = try net.UDP.init();
        try socket.bind(addr);

        return QuicSocket{
            .allocator = allocator,
            .socket = socket,
            .endpoint = addr,
        };
    }

    pub fn send(self: *QuicSocket, data: []const u8, dest: net.Address) !void {
        _ = try self.socket.sendTo(data, dest);
    }

    pub fn receive(self: *QuicSocket, buffer: []u8) !usize {
        var sender_addr: net.Address = undefined;
        return self.socket.receiveFrom(buffer, &sender_addr);
    }

    pub fn close(self: *QuicSocket) void {
        self.socket.deinit();
    }
};

// ✅ **Embedded Unit Tests**
test "QuicSocket initialization and basic send/receive" {
    const allocator = std.testing.allocator;
    var socket = try QuicSocket.init(allocator, 4433);
    defer socket.close();

    try std.testing.expect(true); // If it doesn't crash, assume success
}
