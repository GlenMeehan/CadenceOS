// src/kernel/E820Store.zig

const bi = @import("boot_info.zig");
const e820 = @import("E820.zig");

pub const E820Entry = e820.E820Entry;

const MAX_E820_ENTRIES = 64;

// This lives in the kernel's .bss/.data – safe, kernel-owned memory.
var table: [MAX_E820_ENTRIES]E820Entry = undefined;
var table_count: u32 = 0;

/// Returns the address (as usize) of the first copied entry.
pub fn getTableAddr() usize {
    return @intFromPtr(&table[0]);
}

/// Returns how many entries were copied.
pub fn getTableCount() u32 {
    return table_count;
}

/// Copy directly from boot_info's E820 region into our kernel-owned buffer.
/// DO NOT change E820.zig yet.
pub fn init() void {
    const boot = bi.get();
    const count = boot.e820_count;
    table_count = if (count > MAX_E820_ENTRIES) MAX_E820_ENTRIES else count;

    const src_base = boot.e820_addr;

    var i: u32 = 0;
    while (i < table_count) : (i += 1) {
        const src_addr = src_base + @as(usize, i) * @sizeOf(E820Entry);
        const src_ptr = @as(*const E820Entry, @ptrFromInt(src_addr));
        table[i] = src_ptr.*;
    }
}
