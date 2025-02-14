const std = @import("std");

pub const Error = error{
    PacketLost,
};

pub const Recovery = struct {
    sent_packets: std.AutoHashMap(u64, std.time.Instant), // Packet number → sent time
    acked_packets: std.AutoHashMap(u64, bool), // Packet number → ACK status
    rtt: u64, // Estimated round-trip time (RTT) in nanoseconds
    loss_threshold_ns: u64, // Threshold for packet loss detection

    pub fn init(allocator: std.mem.Allocator) !Recovery {
        return Recovery{
            .sent_packets = std.AutoHashMap(u64, std.time.Instant).init(allocator),
            .acked_packets = std.AutoHashMap(u64, bool).init(allocator),
            .rtt = 0,
            .loss_threshold_ns = 100_000_000, // 100ms default loss detection
        };
    }

    pub fn on_packet_sent(self: *Recovery, packet_number: u64) !void {
        const now = std.time.Instant.now();
        try self.sent_packets.put(packet_number, now);
    }

    pub fn on_ack_received(self: *Recovery, packet_number: u64) !void {
        const now = std.time.Instant.now();

        if (self.sent_packets.get(packet_number)) |sent_time| {
            self.rtt = @max(1, now.since(sent_time));
            try self.acked_packets.put(packet_number, true);
            _ = self.sent_packets.remove(packet_number);
        }
    }

    pub fn detect_loss(self: *Recovery) ![]u64 {
        var lost_packets = std.ArrayList(u64).init(self.sent_packets.allocator);
        var now = std.time.Instant.now();

        var it = self.sent_packets.iterator();
        while (it.next()) |entry| {
            const packet_number = entry.key_ptr.*;
            const sent_time = entry.value_ptr.*;

            if (now.since(sent_time) > self.loss_threshold_ns) {
                try lost_packets.append(packet_number);
            }
        }

        return lost_packets.toOwnedSlice();
    }
};

// ✅ **Embedded Unit Tests**
test "Packet loss detection" {
    const allocator = std.testing.allocator;
    var recovery = try Recovery.init(allocator);
    defer recovery.sent_packets.deinit();
    defer recovery.acked_packets.deinit();

    try recovery.on_packet_sent(1);
    try recovery.on_packet_sent(2);

    // Simulate ACK for packet 1
    try recovery.on_ack_received(1);

    // Simulate loss detection after timeout
    std.time.sleep(150_000_000); // Simulate 150ms delay
    const lost_packets = try recovery.detect_loss();

    try std.testing.expectEqual(lost_packets.len, 1);
    try std.testing.expectEqual(lost_packets[0], 2);
}
