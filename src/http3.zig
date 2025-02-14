const std = @import("std");
const Stream = @import("transport/stream.zig");

pub const Error = error{
    InvalidHttpFrame,
    StreamClosed,
};

pub const Http3FrameType = enum(u8) {
    Data = 0x0,
    Headers = 0x1,
    Settings = 0x4,
};

pub const Http3Frame = struct {
    frame_type: Http3FrameType,
    payload: []const u8,

    pub fn encode(self: Http3Frame, buffer: []u8) !usize {
        if (buffer.len < self.payload.len + 2) return Error.InvalidHttpFrame;

        buffer[0] = @intFromEnum(self.frame_type);
        buffer[1] = @intCast(self.payload.len); // ✅ Store length explicitly

        std.mem.copyForwards(u8, buffer[2..], self.payload); // ✅ Shift by 2 to include length
        return self.payload.len + 2;
    }

    pub fn decode(buffer: []const u8, allocator: std.mem.Allocator) !Http3Frame {
        if (buffer.len < 2) return Error.InvalidHttpFrame; // ✅ Check at least type + length

        const length = buffer[1]; // ✅ Extract length

        if (buffer.len < 2 + length) return Error.InvalidHttpFrame; // ✅ Ensure full payload exists

        const payload_copy = try allocator.dupe(u8, buffer[2 .. 2 + length]); // ✅ Correct slicing

        return Http3Frame{
            .frame_type = @enumFromInt(buffer[0]),
            .payload = payload_copy,
        };
    }
};

pub const Http3Stream = struct {
    stream: Stream.QuicStream,

    pub fn init(allocator: std.mem.Allocator, id: u64) !Http3Stream {
        return Http3Stream{
            .stream = try Stream.QuicStream.init(allocator, id, Stream.StreamType.Bidirectional),
        };
    }

    pub fn send_frame(self: *Http3Stream, frame: Http3Frame) !void {
        var buffer: [256]u8 = undefined;
        const written = try frame.encode(&buffer);

        std.debug.print("send_frame(): Writing {} bytes to QUIC stream {}...\n", .{ written, self.stream.id });

        var total_written: usize = 0;
        while (total_written < written) {
            const bytes_written = try self.stream.write(buffer[total_written..written]);

            if (bytes_written == 0) {
                std.debug.print("send_frame(): Error! Zero bytes written, possible buffer issue.\n", .{});
                return Error.InvalidHttpFrame;
            }

            std.debug.print("send_frame(): Wrote {} bytes (remaining {})...\n", .{ bytes_written, written - total_written });
            total_written += bytes_written;
        }
    }

    pub fn receive_frame(self: *Http3Stream) !Http3Frame {
        std.debug.print("Receiving HTTP/3 frame on QUIC stream {}...\n", .{self.stream.id});

        const payload = self.stream.read() catch |err| {
            std.debug.print("Error: Failed to read payload: {}\n", .{err});
            return err;
        };

        std.debug.print("Raw Payload Received (len {}): {any}\n", .{ payload.len, payload });

        if (payload.len < 2) {
            self.stream.allocator.free(payload); // ✅ Free invalid payload
            return Error.InvalidHttpFrame;
        }

        // ✅ Decode frame, taking ownership of the allocation
        const decoded = Http3Frame.decode(payload, self.stream.allocator) catch |err| {
            self.stream.allocator.free(payload); // ✅ Free before returning error
            return err;
        };

        self.stream.allocator.free(payload); // ✅ Free original payload

        return decoded; // ❌ DO NOT free `decoded.payload` here! Caller owns it
    }

    pub fn flush(self: *Http3Stream, peer: *Http3Stream) !void {
        try self.stream.flush(&peer.stream); // ✅ Correctly pass peer stream
    }

    pub fn close(self: *Http3Stream) void {
        self.stream.close();
    }
};

// ✅ **Embedded Unit Tests**
test "HTTP/3 frame encoding & decoding" {
    const allocator = std.testing.allocator;
    var buffer: [128]u8 = undefined;

    const original_frame = Http3Frame{
        .frame_type = Http3FrameType.Headers,
        .payload = "GET / HTTP/3",
    };

    const written = try original_frame.encode(&buffer);

    // ✅ Decode with allocator
    const decoded = try Http3Frame.decode(buffer[0..written], allocator);

    try std.testing.expectEqual(original_frame.frame_type, decoded.frame_type);
    try std.testing.expectEqualSlices(u8, original_frame.payload, decoded.payload);

    // ✅ Free allocated payload to prevent memory leak
    allocator.free(decoded.payload);
}

test "HTTP/3 stream sending & receiving" {
    const allocator = std.testing.allocator;
    var http3_stream = try Http3Stream.init(allocator, 1);
    defer http3_stream.close();

    const frame = Http3Frame{
        .frame_type = Http3FrameType.Data,
        .payload = "Hello, HTTP/3!",
    };

    try http3_stream.send_frame(frame);
    const received = try http3_stream.receive_frame();

    try std.testing.expectEqual(frame.frame_type, received.frame_type);
    try std.testing.expectEqualSlices(u8, frame.payload, received.payload);

    // ✅ Free `received.payload` after test assertions
    allocator.free(received.payload);
}
