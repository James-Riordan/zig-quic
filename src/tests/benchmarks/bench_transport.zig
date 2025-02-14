const std = @import("std");
const time = std.time;
const Packet = @import("../transport/packet.zig");
const Recovery = @import("../transport/recovery.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    std.debug.print("Benchmarking QUIC transport layer...\n", .{});

    // Measure packet encoding/decoding speed
    var buffer: [256]u8 = undefined;
    var test_packet = Packet.QuicPacket{
        .packet_type = .Handshake,
        .payload = "Benchmarking QUIC Transport",
    };

    var start_time = time.Instant.now();
    for (0..1000) |_| {
        _ = test_packet.encode(&buffer) catch continue;
        _ = Packet.QuicPacket.decode(&buffer) catch continue;
    }
    var end_time = time.Instant.now();
    std.debug.print("  Packet Encoding/Decoding Time: {} ns per iteration\n", .{(end_time.since(start_time) / 1000)});

    // Measure retransmission speed
    var recovery = try Recovery.Recovery.init(allocator);
    defer recovery.sent_packets.deinit();
    defer recovery.acked_packets.deinit();

    start_time = time.Instant.now();
    for (0..1000) |i| {
        try recovery.on_packet_sent(@intCast(i));
    }
    end_time = time.Instant.now();
    std.debug.print("  Packet Retransmission Tracking Time: {} ns per packet\n", .{(end_time.since(start_time) / 1000)});
}
