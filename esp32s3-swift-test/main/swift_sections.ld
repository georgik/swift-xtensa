SECTIONS
{
    /* Discard Swift-specific sections that aren't needed at runtime */
    /DISCARD/ :
    {
        *(.swift1_autolink_entries)
        *("__TEXT, __swift5_entry, regular, no_dead_strip")
        *("__DATA,__objc_imageinfo,regular,no_dead_strip")
        *(.rodata.__swift_reflection_version)
    }
}
