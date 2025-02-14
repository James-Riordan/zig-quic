const std = @import("std");

pub const Error = error{
    RandomGenerationFailed,
};

pub const Random = struct {
    pub fn generate_u64() u64 {
        return std.crypto.random.int(u64);
    }

    pub fn generate_bytes(buffer: []u8) !void {
        if (buffer.len == 0) return Error.RandomGenerationFailed;
        std.crypto.random.bytes(buffer);
    }
};

// ✅ **Embedded Unit Tests**
test "Random number generation" {
    const num1 = Random.generate_u64();
    const num2 = Random.generate_u64();

    try std.testing.expect(num1 != num2); // Shouldn't be the same

    var buffer1: [16]u8 = undefined;
    var buffer2: [16]u8 = undefined;

    try Random.generate_bytes(&buffer1);
    try Random.generate_bytes(&buffer2);

    try std.testing.expect(buffer1[0] != buffer2[0]); // High chance of different values
}
