// src/kernel/convert.zig

pub fn toHex(comptime T: type, value: T, buf: []u8) []u8 {
    const info = @typeInfo(T);
    const bits = switch (info) {
        .int => |intinfo| intinfo.bits,
        else => @compileError("toHex only supports integer types"),
    };
        const digits = bits / 4;
        if (buf.len < digits)
            @panic("hex buffer too small");

    var i: usize = 0;
    while (i < digits) : (i += 1) {
        // Calculate shift directly from i instead of decrementing
        const shift_bits = (digits - 1 - i) * 4;
        const ShiftType = if (bits == 64) u6 else if (bits == 32) u5 else if (bits == 16) u4 else u3;
        const shift_amt = @as(ShiftType, @intCast(shift_bits));
        const nibble = @as(u4, @truncate((value >> shift_amt) & 0xF));
        buf[i] = "0123456789ABCDEF"[nibble];
    }
    return buf[0..digits];
}
