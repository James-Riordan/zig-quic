const std = @import("std");
const testing = std.testing;
const Congestion = @import("../../transport/congestion.zig");

test "QUIC congestion control - slow start & congestion avoidance" {
    var cc = Congestion.CongestionControl.init(Congestion.CongestionAlgorithm.NewReno);

    try testing.expectEqual(cc.get_cwnd(), 1200);

    // Simulate packet transmissions and growth in congestion window
    for (0..5) |_| {
        cc.on_packet_sent();
    }
    try testing.expect(cc.get_cwnd() > 1200);

    // Simulate packet loss and ensure window halves
    cc.on_packet_lost();
    try testing.expect(cc.get_cwnd() < 1200);
}

test "QUIC congestion control - BBR mode" {
    var cc = Congestion.CongestionControl.init(Congestion.CongestionAlgorithm.BBR);

    try testing.expectEqual(cc.get_cwnd(), 1200);

    // Simulate multiple packet transmissions in BBR mode
    for (0..10) |_| {
        cc.on_packet_sent();
    }

    try testing.expect(cc.get_cwnd() > 1200);
}
