/* Exception handling for Xtensa ESP32-S3 */

/* Vector table */
SECTIONS {
  .vectors : ALIGN(4)
  {
    _vectors_start = .;
    . = . + VECTORS_SIZE;
    _vectors_end = .;
  } > vectors_seg
}
