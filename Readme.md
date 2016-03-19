# AVR-Development-Environment-Script
Compiles the latest AVR tools such as avr-gcc, avr-libc, avrdude and more

```bash
# Compile the sources, NO root required.
./build

# Add the new environment at the beginning of $PATH
PATH=`pwd`/bin/bin:$PATH
export PATH

# Add "-flto -fuse-linker-plugin" to your CC_FLAGS and LD_FLAGS in the makefile
# if you want to compile a project with avr-gcc 5.3 and LTO

# Clean the source if you like to
./build clean
./build cleanall
```

## Original source:
https://github.com/arduino/Arduino/issues/660#issuecomment-120433193
