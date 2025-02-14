const std = @import("std");
const time = std.time;
const Http3 = @import("../http3.zig");

pub fn main() !void {
    std.debug.print("Benchmarking HTTP/3 performance...\n", .{});

    var buffer: [1024]u8 = undefined;
    var test_frame = Http3.Http3Frame{
        .frame_type = Http3.Http3FrameType.Headers,
        .payload = "GET / HTTP/3",
    };

    // Measure frame encoding/decoding speed
    var start_time = time.Instant.now();
    for (0..1000) |_| {
        _ = test_frame.encode(&buffer) catch continue;
        _ = Http3.Http3Frame.decode(&buffer) catch continue;
    }
    var end_time = time.Instant.now();
    std.debug.print("  Frame Encoding/Decoding Time: {} ns per iteration\n", .{(end_time.since(start_time) / 1000)});

    // Measure performance with large payloads
    var large_payload: [8192]u8 = undefined;
    std.crypto.random.bytes(&large_payload);

    var large_frame = Http3.Http3Frame{
        .frame_type = Http3.Http3FrameType.Data,
        .payload = &large_payload,
    };

    start_time = time.Instant.now();
    for (0..500) |_| {
        _ = large_frame.encode(&buffer) catch continue;
        _ = Http3.Http3Frame.decode(&buffer) catch continue;
    }
    end_time = time.Instant.now();
    std.debug.print("  Large Frame Processing Time: {} ns per iteration\n", .{(end_time.since(start_time) / 500)});
}
