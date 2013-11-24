ruby tools/ifdef_cleaner.rb --def=VM_MIXEDMAP --undef=VM_XIP --kernel_version=2.6.27 --input_file=fs/axfs/axfs_bdev.c --output_file=../branches/linux/fs/axfs/axfs_bdev.c
ruby tools/ifdef_cleaner.rb --def=VM_MIXEDMAP --undef=VM_XIP,OLD_POINT --kernel_version=2.6.27 --input_file=fs/axfs/axfs_mtd.c --output_file=../branches/linux/fs/axfs/axfs_mtd.c
ruby tools/ifdef_cleaner.rb --def=VM_MIXEDMAP --undef=VM_XIP --kernel_version=2.6.27 --input_file=fs/axfs/axfs_profiling.c --output_file=../branches/linux/fs/axfs/axfs_profiling.c
ruby tools/ifdef_cleaner.rb --def=VM_MIXEDMAP --undef=VM_XIP --kernel_version=2.6.27 --input_file=fs/axfs/axfs_uml.c --output_file=../branches/linux/fs/axfs/axfs_uml.c
ruby tools/ifdef_cleaner.rb --def=VM_MIXEDMAP,VM_CAN_NONLINEAR --undef=VM_XIP --kernel_version=2.6.27 --input_file=fs/axfs/axfs_inode.c --output_file=../branches/linux/fs/axfs/axfs_inode.c
ruby tools/ifdef_cleaner.rb --def=VM_MIXEDMAP,NO_PHYSMEM --undef=VM_XIP --kernel_version=2.6.27 --input_file=fs/axfs/axfs_super.c --output_file=../branches/linux/fs/axfs/axfs_super.c
ruby tools/ifdef_cleaner.rb --def=VM_MIXEDMAP,ALL_VERSIONS --undef=VM_XIP --kernel_version=2.6.27 --input_file=fs/axfs/axfs_uncompress.c --output_file=../branches/linux/fs/axfs/axfs_uncompress.c
ruby tools/ifdef_cleaner.rb --def=VM_MIXEDMAP,ALL_VERSIONS --undef=VM_XIP --kernel_version=2.6.27 --input_file=include/linux/axfs.h --output_file=../branches/linux/include/linux/axfs.h
