package file;

import "core:mem";
import "core:os";
import "core:slice";


File :: struct {
  path: string,
  contents: []u8,
}

read :: proc(path: string) -> (File, os.Errno) {
  handle, file_err := os.open("test.vi")
	defer os.close(handle)

	file_info, stat_err := os.stat("test.vi")
	
	if file_err == 0 && stat_err == 0 {
		ptr: rawptr = mem.alloc(cast(int)file_info.size)
		defer mem.free(ptr)
		buffer: []u8 = slice.bytes_from_ptr(ptr, cast(int)file_info.size)
		os.read(handle, buffer);
    return File { path, buffer }, 0
  } else {
    return ---, file_err
  }
}

close :: proc(file: ^File) {
  mem.free(slice.as_ptr(file.contents))
}