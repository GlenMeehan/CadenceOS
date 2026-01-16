// src/kernel/E820.zig

pub const E820Entry = extern struct {
    base: u64,
    length: u64,
    entry_type: u32,
    acpi: u32,
};

var table_addr: usize = 0;
var table_count: usize = 0;

pub fn setTable(addr: usize, count: usize) void {
    table_addr = addr;
    table_count = count;
}

pub fn getCount() usize {
    return table_count;
}

pub fn getEntry(index: usize) ?E820Entry {
    if (index >= table_count) return null;

    const addr = table_addr + index * @sizeOf(E820Entry);
    const ptr = @as(*const E820Entry, @ptrFromInt(addr));
    return ptr.*;
}

