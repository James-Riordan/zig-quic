const std = @import("std");
const testing = std.testing;

test "Include all integration tests" {
    _ = @import("test_congestion.zig");
    _ = @import("test_end_to_end.zig");
    _ = @import("test_migration.zig");
}
