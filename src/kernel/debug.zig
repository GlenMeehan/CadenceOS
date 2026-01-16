//src/kernel/debug.zig
const vga = @import("vga.zig");
const e820 = @import("E820.zig");
const conv = @import("convert.zig");
const PHYS_E820: usize = 0x0009_0000;
const ENTRY_SIZE: usize = 24;


fn addr(entry: usize, offset: usize) usize {
    return PHYS_E820 + entry * ENTRY_SIZE + offset;
}

fn readU64(a: usize) u64 {
    return @as(*volatile u64, @ptrFromInt(a)).*;
}

fn readU32(a: usize) u32 {
    return @as(*volatile u32, @ptrFromInt(a)).*;
}


pub fn dumpFirstEntries() void {
    // Entry 0 only, at first
    const base0 = readU64(addr(0, 0));
    const len0  = readU64(addr(0, 8));
    const type0 = readU32(addr(0, 16));
    const acpi0 = readU32(addr(0, 20));

    var bufa: [64]u8 = undefined;
    const base0_hex = conv.toHex(u64, base0, bufa[0..]);
    vga.writeStringAt(10, 0, base0_hex, 15, 0);

    var bufb: [64]u8 = undefined;
    const len0_hex = conv.toHex(u64, len0, bufb[0..]);
    vga.writeStringAt(10, 18, len0_hex, 15, 0);

    var bufc: [32]u8 = undefined;
    const type0_hex = conv.toHex(u32, type0, bufc[0..]);
    vga.writeStringAt(10, 35, type0_hex, 15, 0);

    var bufd: [32]u8 = undefined;
    const acpi0_hex = conv.toHex(u32, acpi0, bufd[0..]);
    vga.writeStringAt(10, 44, acpi0_hex, 15, 0);

}

pub fn pause() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}
