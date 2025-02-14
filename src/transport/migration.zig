const std = @import("std");
const net = std.net;

pub const Error = error{
    MigrationFailed,
    PathValidationFailed,
};

pub const Migration = struct {
    allocator: std.mem.Allocator,
    original_address: net.Address,
    current_address: net.Address,

    pub fn init(allocator: std.mem.Allocator, initial_address: net.Address) !Migration {
        return Migration{
            .allocator = allocator,
            .original_address = initial_address,
            .current_address = initial_address,
        };
    }

    pub fn update_path(self: *Migration, new_address: net.Address) !void {
        // Simulate path validation before migration
        if (!try self.validate_path(new_address)) {
            return Error.PathValidationFailed;
        }

        self.current_address = new_address;
    }

    fn validate_path(self: *Migration, new_address: net.Address) !bool {
        _ = self; // For now, assume all paths are valid. Future: Add RTT checks.

        // Simulate basic NAT traversal check (e.g., STUN or other validation)
        return new_address.port != 0;
    }
};

// ✅ **Embedded Unit Tests**
test "Migration update path" {
    const allocator = std.testing.allocator;
    const initial_addr = try net.Address.parseIp4("192.168.1.100", 4433);
    const new_addr = try net.Address.parseIp4("10.0.0.200", 4433);

    var migration = try Migration.init(allocator, initial_addr);
    try migration.update_path(new_addr);

    try std.testing.expectEqual(migration.current_address, new_addr);
}
