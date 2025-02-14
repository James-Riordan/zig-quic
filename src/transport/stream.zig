const std = @import("std");

pub const Error = error{
    StreamClosed,
    BufferOverflow,
};

pub const StreamType = enum {
    Bidirectional,
    Unidirectional,
};

pub const QuicStream = struct {
    allocator: std.mem.Allocator,
    id: u64,
    stream_type: StreamType,
    buffer: std.ArrayList(u8),
    closed: bool,

    pub fn init(allocator: std.mem.Allocator, id: u64, stream_type: StreamType) !QuicStream {
        return QuicStream{
            .allocator = allocator,
            .id = id,
            .stream_type = stream_type,
            .buffer = std.ArrayList(u8).init(allocator),
            .closed = false,
        };
    }

    pub fn write(self: *QuicStream, data: []const u8) !void {
        if (self.closed) return Error.StreamClosed;
        try self.buffer.appendSlice(data);
    }

    pub fn read(self: *QuicStream) ![]const u8 {
        if (self.closed) return Error.StreamClosed;
        return self.buffer.items;
    }

    pub fn close(self: *QuicStream) void {
        self.closed = true;
        self.buffer.deinit();
    }
};

// ✅ **Embedded Unit Tests**
test "QuicStream lifecycle" {
    const allocator = std.testing.allocator;
    var stream = try QuicStream.init(allocator, 1, StreamType.Bidirectional);
    defer stream.close();

    try std.testing.expectEqual(stream.closed, false);

    try stream.write("Hello, QUIC!");
    const received = try stream.read();
    try std.testing.expectEqualSlices(u8, "Hello, QUIC!", received);

    stream.close();
    try std.testing.expectEqual(stream.closed, true);
}
