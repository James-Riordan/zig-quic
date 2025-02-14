const std = @import("std");

pub const Error = error{
    TimerNotStarted,
    TimerExpired,
};

pub const Timer = struct {
    start_time: ?std.time.Instant,
    duration_ns: u64,

    pub fn init(duration_ns: u64) Timer {
        return Timer{
            .start_time = null,
            .duration_ns = duration_ns,
        };
    }

    pub fn start(self: *Timer) void {
        self.start_time = std.time.Instant.now();
    }

    pub fn has_expired(self: *Timer) !bool {
        if (self.start_time == null) return Error.TimerNotStarted;
        return std.time.Instant.now().since(self.start_time.?) >= self.duration_ns;
    }

    pub fn reset(self: *Timer) void {
        self.start_time = std.time.Instant.now();
    }
};

// ✅ **Embedded Unit Tests**
test "Timer expiration handling" {
    var timer = Timer.init(50_000_000); // 50ms timeout

    try std.testing.expectError(Error.TimerNotStarted, timer.has_expired());

    timer.start();
    std.time.sleep(60_000_000); // Sleep for 60ms
    try std.testing.expect(timer.has_expired());

    timer.reset();
    try std.testing.expectError(Error.TimerNotStarted, timer.has_expired());
}
