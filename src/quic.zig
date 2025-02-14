const std = @import("std");
const Packet = @import("transport/packet.zig");
const Connection = @import("transport/connection.zig");

pub const Error = error{
    ConnectionFailed,
    PacketLoss,
    Timeout,
    InvalidState,
};

pub const State = enum {
    Initial,
    Handshake,
    Established,
    Closed,
};

pub const QuicSession = struct {
    allocator: std.mem.Allocator,
    state: State,
    connection: Connection,

    pub fn init(allocator: std.mem.Allocator) !QuicSession {
        return QuicSession{
            .allocator = allocator,
            .state = State.Initial,
            .connection = try Connection.init(allocator),
        };
    }

    pub fn handshake(self: *QuicSession) !void {
        if (self.state != State.Initial) return Error.InvalidState;
        try self.connection.establish();
        self.state = State.Handshake;
    }

    pub fn establish(self: *QuicSession) !void {
        if (self.state != State.Handshake) return Error.InvalidState;
        self.state = State.Established;
    }

    pub fn close(self: *QuicSession) void {
        self.state = State.Closed;
        self.connection.close();
    }
};

// ✅ **Embedded Unit Tests**
test "QuicSession lifecycle" {
    const allocator = std.testing.allocator;
    var session = try QuicSession.init(allocator);
    defer session.close();

    try std.testing.expectEqual(session.state, State.Initial);

    try session.handshake();
    try std.testing.expectEqual(session.state, State.Handshake);

    try session.establish();
    try std.testing.expectEqual(session.state, State.Established);

    session.close();
    try std.testing.expectEqual(session.state, State.Closed);
}
