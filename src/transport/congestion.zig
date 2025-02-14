const std = @import("std");

pub const Error = error{
    CongestionControlFailure,
};

pub const CongestionAlgorithm = enum {
    NewReno,
    BBR,
};

pub const CongestionControl = struct {
    cwnd: usize, // Congestion window size
    ssthresh: usize, // Slow start threshold
    algorithm: CongestionAlgorithm,

    pub fn init(algorithm: CongestionAlgorithm) CongestionControl {
        return CongestionControl{
            .cwnd = 1200, // Default QUIC Initial Congestion Window
            .ssthresh = 65535,
            .algorithm = algorithm,
        };
    }

    pub fn on_packet_sent(self: *CongestionControl) void {
        if (self.cwnd < self.ssthresh) {
            // Slow start phase: Exponential growth
            self.cwnd += 1200;
        } else {
            // Congestion avoidance: Additive increase
            self.cwnd += 1200 / self.cwnd;
        }
    }

    pub fn on_packet_lost(self: *CongestionControl) void {
        // NewReno congestion control: Halve the window
        self.ssthresh = self.cwnd / 2;
        self.cwnd = self.ssthresh;
    }

    pub fn get_cwnd(self: *CongestionControl) usize {
        return self.cwnd;
    }
};

// ✅ **Embedded Unit Tests**
test "Congestion control (NewReno) behavior" {
    var cc = CongestionControl.init(CongestionAlgorithm.NewReno);

    try std.testing.expectEqual(cc.get_cwnd(), 1200);

    cc.on_packet_sent();
    try std.testing.expect(cc.get_cwnd() > 1200);

    cc.on_packet_lost();
    try std.testing.expect(cc.get_cwnd() < 1200);
}
