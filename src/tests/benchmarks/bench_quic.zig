const std = @import("std");
const time = std.time;
const Connection = @import("../transport/connection.zig");
const Http3 = @import("../http3.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const num_requests = 100;

    std.debug.print("Benchmarking QUIC protocol performance...\n", .{});

    var total_latency: u64 = 0;
    var total_throughput: usize = 0;

    for (0..num_requests) |_| {
        var connection = try Connection.init(allocator);
        defer connection.close();

        const start_time = time.Instant.now();
        try connection.establish();
        var end_time = time.Instant.now();

        total_latency += end_time.since(start_time);

        var http3_stream = try Http3.Http3Stream.init(allocator, 1);
        defer http3_stream.close();

        const request = Http3.Http3Frame{
            .frame_type = Http3.Http3FrameType.Headers,
            .payload = "GET / HTTP/3",
        };

        try http3_stream.send_frame(request);
        const response = try http3_stream.receive_frame();

        total_throughput += response.payload.len;
    }

    const avg_latency = total_latency / num_requests;
    const avg_throughput = total_throughput / num_requests;

    std.debug.print("QUIC Benchmark Results:\n", .{});
    std.debug.print("  Average Handshake Latency: {} ns\n", .{avg_latency});
    std.debug.print("  Average Throughput: {} bytes/request\n", .{avg_throughput});
}
