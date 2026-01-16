const e820 = @import("E820.zig");
const vga = @import("vga.zig");
const conv = @import("convert.zig");

const E820Entry = e820.E820Entry;

/// Helper to print one entry
fn printEntry(prefix: []const u8, entry: E820Entry) void {
    var buf: [32]u8 = undefined;

    vga.writeString(prefix, 15, 4);
    vga.writeString(" base=", 15, 4);
    vga.writeString(conv.toHex(u64, entry.base, &buf), 15, 4);

    vga.writeString(" length=", 15, 4);
    vga.writeString(conv.toHex(u64, entry.length, &buf), 15, 4);

    vga.writeString(" type=", 15, 4);
    vga.writeString(conv.toHex(u32, entry.entry_type, &buf), 15, 4);

    vga.writeString("\n", 15, 4);
}

/// First test function
pub fn test1() void {
    var it1= e820.iterate();
    const first = it1.next() orelse unreachable;
    printEntry("test1:", first);
}

/// Second test function
pub fn test2() void {
    var it2 = e820.iterate();
    const first = it2.next() orelse unreachable;
    printEntry("test2:", first);
}

/// Third test function
pub fn test3() void {
    var it3 = e820.iterate();
    const first = it3.next() orelse unreachable;
    printEntry("test3:", first);
}


pub fn testIteratorState(label: []const u8) void {
    var it = e820.iterate();

    var buf: [32]u8 = undefined;

    // Before first next()
    vga.writeString(label, 15, 4);
    vga.writeString(" BEFORE1 current=", 15, 4);
    vga.writeString(conv.toHex(u32, it.current, &buf), 15, 4);
    vga.writeString(" count=", 15, 4);
    vga.writeString(conv.toHex(u32, it.count, &buf), 15, 4);
    vga.writeString("\n", 15, 4);

    const first = it.next() orelse unreachable;

    // Before second next()
    vga.writeString(label, 15, 4);
    vga.writeString(" BEFORE2 current=", 15, 4);
    vga.writeString(conv.toHex(u32, it.current, &buf), 15, 4);
    vga.writeString(" count=", 15, 4);
    vga.writeString(conv.toHex(u32, it.count, &buf), 15, 4);
    vga.writeString("\n", 15, 4);

    const second = it.next() orelse unreachable;

    // Optional: print entries
    _ = first;
    _ = second;
}
