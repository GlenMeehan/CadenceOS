// src/kernel/panic.zig

pub fn panic(message: []const u8, _: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    const vga_ptr = @as([*]volatile u16, @ptrFromInt(0xB8000));
    var i: usize = 0;
    while (i < 80 * 25) : (i += 1) {
        vga_ptr[i] = 0x4F20;
    }

    vga.writeStringAt(10, 0, "KERNEL PANIC!", 0x0F, 0x04);
    vga.writeStringAt(12, 0, message, 0x0F, 0x04);

    // Show return address if available
    if (ret_addr) |addr| {
        var buf: [16]u8 = undefined;
        vga.writeStringAt(14, 0, "At address: ", 0x0F, 0x04);
        vga.writeStringAt(14, 12, conv.toHex(u64, addr, &buf), 0x0F, 0x04);
    }

    while (true) {
        asm volatile ("cli; hlt");
    }
}
