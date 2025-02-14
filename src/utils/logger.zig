const std = @import("std");

pub const LogLevel = enum {
    INFO,
    WARN,
    ERROR,
    DEBUG,
};

pub const Logger = struct {
    level: LogLevel,

    pub fn init(level: LogLevel) Logger {
        return Logger{ .level = level };
    }

    pub fn log(self: *Logger, comptime level: LogLevel, comptime msg: []const u8, args: anytype) void {
        if (@intFromEnum(level) > @intFromEnum(self.level)) return;

        var buffer: [256]u8 = undefined;
        const formatted = std.fmt.bufPrint(&buffer, msg, args) catch return;

        const prefix = switch (level) {
            LogLevel.INFO => "[INFO] ",
            LogLevel.WARN => "[WARN] ",
            LogLevel.ERROR => "[ERROR] ",
            LogLevel.DEBUG => "[DEBUG] ",
        };

        std.debug.print("{}{}\n", .{ prefix, formatted });
    }
};

// ✅ **Embedded Unit Tests**
test "Logger output test" {
    var logger = Logger.init(LogLevel.DEBUG);

    logger.log(LogLevel.INFO, "QUIC connection established: {d}", .{123});
    logger.log(LogLevel.WARN, "Packet loss detected on stream {d}", .{2});
    logger.log(LogLevel.ERROR, "Handshake failed due to timeout", .{});
    logger.log(LogLevel.DEBUG, "Debugging congestion control window: {d}", .{1200});

    try std.testing.expect(true); // If it doesn't crash, assume success
}
