const std = @import("std");

pub const Error = error{
    InvalidPacket,
    BufferTooSmall,
    EncryptionFailed,
};

pub const PacketType = enum(u8) {
    Initial = 0x0,
    Handshake = 0x1,
    Retry = 0x2,
    OneRTT = 0x3,
};

pub const Packet = struct {
    packet_type: PacketType,
    connection_id: u64,
    payload: []const u8,

    pub fn encode(self: Packet, buffer: []u8) !usize {
        if (buffer.len < self.payload.len + 10) return Error.BufferTooSmall;

        buffer[0] = @intFromEnum(self.packet_type);
        std.mem.writeInt(u64, buffer[1..9], self.connection_id, .big);
        std.mem.copyForwards(u8, buffer[9..], self.payload); // ✅ Use copyForwards

        return self.payload.len + 9;
    }

    pub fn decode(buffer: []const u8) !Packet {
        if (buffer.len < 9) return Error.InvalidPacket;

        return Packet{
            .packet_type = @enumFromInt(buffer[0]),
            .connection_id = std.mem.readInt(u64, buffer[1..9], .big),
            .payload = buffer[9..],
        };
    }
};

// ✅ **Embedded Unit Tests**
test "Packet encoding & decoding" {
    var buffer: [128]u8 = undefined;
    const original_packet = Packet{
        .packet_type = PacketType.Initial,
        .connection_id = 0x1234567890abcdef,
        .payload = "Hello QUIC!",
    };

    const written = try original_packet.encode(&buffer);
    const decoded = try Packet.decode(buffer[0..written]);

    try std.testing.expectEqual(original_packet.packet_type, decoded.packet_type);
    try std.testing.expectEqual(original_packet.connection_id, decoded.connection_id);
    try std.testing.expectEqualSlices(u8, original_packet.payload, decoded.payload);
}
