//src/kernel.zig

fn markUsableFromE820() void {
    var iter = e820.iterate();
    var region_count: u32 = 0;

    while (iter.next()) |entry| {
        // Only mark type 1 (usable) regions
        if (entry.entry_type != 1) continue;

        region_count += 1;

        // Show we're processing this region
        var buf: [8]u8 = undefined;
        vga.writeStringAt(20, 0, "Processing region: ", 15, 0);
        vga.writeStringAt(20, 19, conv.toHex(u32, region_count, &buf), 15, 0);

        var addr: u64 = entry.base;
        const end: u64 = entry.base + entry.length;

        // Align start up to the next page boundary
        addr = (addr + PAGE_SIZE - 1) & ~(PAGE_SIZE - 1);

        while (addr + PAGE_SIZE <= end) : (addr += PAGE_SIZE) {
            const phys_addr: usize = @intCast(addr);
            phys_bitmap.markFree(phys_addr);
        }
    }

    vga.writeStringAt(21, 0, "Bitmap init complete!", 15, 0);
}
