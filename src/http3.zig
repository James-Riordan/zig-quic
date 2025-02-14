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
        if (buffer.len < self.payload.len + 1) return Error.InvalidHttpFrame;
        buffer[0] = @intFromEnum(self.frame_type);
        std.mem.copyForwards(u8, buffer[1..], self.payload);
        return self.payload.len + 1;
    }

    pub fn decode(buffer: []const u8) !Http3Frame {
        if (buffer.len < 1) return Error.InvalidHttpFrame;
        return Http3Frame{
            .frame_type = @enumFromInt(buffer[0]),
            .payload = buffer[1..],
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
        try self.stream.write(buffer[0..written]);
    }

    pub fn receive_frame(self: *Http3Stream) !Http3Frame {
        const payload = try self.stream.read();
        return try Http3Frame.decode(payload);
    }

    pub fn close(self: *Http3Stream) void {
        self.stream.close();
    }
};

// ✅ **Embedded Unit Tests**
test "HTTP/3 frame encoding & decoding" {
    var buffer: [128]u8 = undefined;
    const original_frame = Http3Frame{
        .frame_type = Http3FrameType.Headers,
        .payload = "GET / HTTP/3",
    };

    const written = try original_frame.encode(&buffer);
    const decoded = try Http3Frame.decode(buffer[0..written]);

    try std.testing.expectEqual(original_frame.frame_type, decoded.frame_type);
    try std.testing.expectEqualSlices(u8, original_frame.payload, decoded.payload);
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
}
