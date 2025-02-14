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

    pub fn write(self: *QuicStream, data: []const u8) !usize {
        if (self.closed) return Error.StreamClosed;

        try self.buffer.appendSlice(data);
        return data.len; // ✅ Return number of bytes written
    }

    pub fn read(self: *QuicStream) ![]u8 {
        if (self.closed) return Error.StreamClosed;
        if (self.buffer.items.len == 0) {
            std.debug.print("read(): No data available on QUIC stream {}\n", .{self.id});
            return Error.StreamClosed;
        }

        std.debug.print("read(): Reading {} bytes from QUIC stream {}...\n", .{ self.buffer.items.len, self.id });

        // ✅ Allocate buffer and copy data
        const data = try self.allocator.alloc(u8, self.buffer.items.len);
        std.mem.copyForwards(u8, data, self.buffer.items);

        // ✅ Validate buffer content before returning
        if (data.len > 0 and data[0] == 0) {
            std.debug.print("Warning: Read returned unexpected null bytes!\n", .{});
        }

        self.buffer.clearRetainingCapacity(); // ✅ Clear after reading
        return data;
    }

    // TODO flesh out flush (pun intended)
    pub fn flush(self: *QuicStream, peer: *QuicStream) !void {
        if (self.closed) return Error.StreamClosed;
        if (self.buffer.items.len == 0) {
            std.debug.print("flush(): Nothing to flush on QUIC stream {}\n", .{self.id});
            return;
        }

        std.debug.print("flush(): Transferring {} bytes from QUIC stream {} → {}...\n", .{ self.buffer.items.len, self.id, peer.id });

        if (self.buffer.items.len > 0) {
            try peer.buffer.appendSlice(self.buffer.items);
        } else {
            std.debug.print("flush(): Warning! Attempted to transfer empty buffer!\n", .{});
        }

        std.debug.print("flush(): Peer QUIC stream {} now has {} bytes\n", .{ peer.id, peer.buffer.items.len });

        self.buffer.clearRetainingCapacity();
    }

    pub fn close(self: *QuicStream) void {
        if (!self.closed) { // ✅ Prevent double-free issue
            self.closed = true;
            self.buffer.deinit(); // ✅ Correct deallocation
        }
    }
};

// ✅ **Embedded Unit Tests**
test "QuicStream lifecycle" {
    const allocator = std.testing.allocator;
    var stream = try QuicStream.init(allocator, 1, StreamType.Bidirectional);
    defer stream.close();

    try std.testing.expectEqual(stream.closed, false);

    _ = try stream.write("Hello, QUIC!"); // ✅ FIX: Discard return value

    const received = try stream.read();
    defer allocator.free(received);

    try std.testing.expectEqualSlices(u8, "Hello, QUIC!", received);

    stream.close();
    try std.testing.expectEqual(stream.closed, true);
}
