const std = @import("std");
const testing = std.testing;
const Congestion = @import("zig_quic").transport.congestion;

test "QUIC congestion control - slow start & congestion avoidance" {
    var cc = Congestion.CongestionControl.init(Congestion.CongestionAlgorithm.NewReno);

    try testing.expectEqual(cc.get_cwnd(), 1200);

    // Simulate packet transmissions and growth in congestion window
    for (0..5) |_| {
        cc.on_packet_sent();
    }
    try testing.expect(cc.get_cwnd() > 1200);

    // Simulate packet loss and ensure window significantly reduces
    std.debug.print("Before packet loss, cwnd: {}\n", .{cc.get_cwnd()});
    const old_cwnd = cc.get_cwnd();
    cc.on_packet_lost();
    std.debug.print("After packet loss, cwnd: {}\n", .{cc.get_cwnd()});

    try testing.expect(cc.get_cwnd() < old_cwnd); // ✅ Ensure cwnd decreases
    try testing.expect(cc.get_cwnd() <= old_cwnd / 2); // ✅ Verify proper halving behavior
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
