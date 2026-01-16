// src/kernel/boot_info.zig

pub const BootInfo = extern struct {
    kernel_start: u64,       // 0x00
    kernel_end: u64,         // 0x08
    kernel_size: u64,        // 0x10
    stack_top: u64,          // 0x18
    e820_count: u32,         // 0x20
    _padding: u32,           // 0x24
    e820_addr: u64,          // 0x28
    page_table_base: u64,    // 0x30
};

const BOOT_INFO_ADDR = 0x7000;

pub fn get() *const BootInfo {
    return @as(*const BootInfo, @ptrFromInt(BOOT_INFO_ADDR));
}
