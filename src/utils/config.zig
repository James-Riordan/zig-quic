const std = @import("std");

pub const Config = struct {
    max_packet_size: usize,
    initial_rtt: u64, // in nanoseconds
    congestion_algorithm: enum { NewReno, BBR },
    enable_logging: bool,

    pub fn init() Config {
        return Config{
            .max_packet_size = 1350,
            .initial_rtt = 100_000_000, // 100ms
            .congestion_algorithm = .NewReno,
            .enable_logging = true,
        };
    }

    pub fn set_max_packet_size(self: *Config, size: usize) void {
        self.max_packet_size = size;
    }

    pub fn set_congestion_algorithm(self: *Config, algo: @TypeOf(self.congestion_algorithm)) void {
        self.congestion_algorithm = algo;
    }

    pub fn set_logging(self: *Config, enabled: bool) void {
        self.enable_logging = enabled;
    }
};

// ✅ **Embedded Unit Tests**
test "Configuration defaults & modifications" {
    var config = Config.init();

    try std.testing.expectEqual(config.max_packet_size, 1350);
    try std.testing.expectEqual(config.initial_rtt, 100_000_000);
    try std.testing.expect(config.enable_logging);

    config.set_max_packet_size(1500);
    try std.testing.expectEqual(config.max_packet_size, 1500);

    config.set_congestion_algorithm(.BBR);
    try std.testing.expectEqual(config.congestion_algorithm, .BBR);

    config.set_logging(false);
    try std.testing.expect(!config.enable_logging);
}
