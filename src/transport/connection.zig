const std = @import("std");
const Packet = @import("packet.zig").Packet;
const PacketType = @import("packet.zig").PacketType;

pub const Error = error{
    ConnectionFailed,
    InvalidPacket,
    Timeout,
};

pub const ConnectionState = enum {
    Idle,
    Connecting,
    Established,
    Closing,
    Closed,
};

pub const Connection = struct {
    allocator: std.mem.Allocator,
    state: ConnectionState,
    connection_id: u64,
    buffer: [128]u8,
    buffer_len: usize, // Track the actual stored data length

    pub fn init(allocator: std.mem.Allocator) !Connection {
        return Connection{
            .allocator = allocator,
            .state = ConnectionState.Idle,
            .connection_id = std.crypto.random.int(u64),
            .buffer = undefined,
            .buffer_len = 0, // Ensure no leftover data
        };
    }

    pub fn establish(self: *Connection) !void {
        if (self.state != ConnectionState.Idle) return Error.ConnectionFailed;
        self.state = ConnectionState.Connecting;

        // Simulate handshake
        var packet = Packet{
            .packet_type = PacketType.Initial,
            .connection_id = self.connection_id,
            .payload = "QUIC handshake",
        };

        const encoded_len = try packet.encode(&self.buffer);
        self.buffer_len = encoded_len; // Store valid buffer length

        self.state = ConnectionState.Established;
    }

    pub fn send(self: *Connection, data: []const u8) !void {
        if (self.state != ConnectionState.Established) return Error.ConnectionFailed;

        var packet = Packet{
            .packet_type = PacketType.OneRTT,
            .connection_id = self.connection_id,
            .payload = data,
        };

        const encoded_len = try packet.encode(&self.buffer);
        self.buffer_len = encoded_len; // Track actual data length
    }

    pub fn receive(self: *Connection) ![]const u8 {
        if (self.state != ConnectionState.Established) return Error.ConnectionFailed;

        const decoded = try Packet.decode(self.buffer[0..self.buffer_len]); // Only read valid data

        return decoded.payload;
    }

    pub fn close(self: *Connection) void {
        self.state = ConnectionState.Closed;
    }
};

// ✅ **Embedded Unit Tests**
test "Connection lifecycle" {
    const allocator = std.testing.allocator;
    var conn = try Connection.init(allocator);
    defer conn.close();

    try std.testing.expectEqual(conn.state, ConnectionState.Idle);

    try conn.establish();
    try std.testing.expectEqual(conn.state, ConnectionState.Established);

    try conn.send("Test data");
    const received = try conn.receive();
    try std.testing.expectEqualSlices(u8, "Test data", received); // ✅ Should now match correctly

    conn.close();
    try std.testing.expectEqual(conn.state, ConnectionState.Closed);
}
