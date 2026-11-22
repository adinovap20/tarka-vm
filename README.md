# TarkaVM Instruction Set Architecture

This is the initial version of the instruction set architecture of TarkaVM - supporting only handful of instructions. 

## Virtual Machine State

The Tarka Virtual Machine contains only a stack of u64 items. It also contains an instruction pointer pointing at the bytecode to be executed.

Whenever an integer is pushed, it is converted to u64 representation and then pushed on the stack. The numbers will be read in the little endian format.

If the operations like pop, dup, swap, add, sub, etc. do not contain sufficient elements on the stack - the virtual machine will panic and return a runtime stack underflow error.

If the mathematical operations like add, sub, etc. overflow 64-bit integer values, the vm will panic and return integer overflow error.

If the execution reaches the end of the bycode without `halt` instruction, it will treat it as success and exit normally with exit code 0.

## Supported Instructions

### 0X series

1. `halt` - 0x00 - Immediately stops the execution of the vm and returns exit code 0
2. `push <int>` - 0x01 \[8 bytes] - Reads the next 8 bytes as u64 and pushes it on top of stack - \[... a] --> \[... a b]
3. `pop` - 0x02 - Pops the top u64 value from the top of the stack - \[... a b] --> \[... a]
4. `dup` - 0x03 - Duplicates the value on top of the stack - \[... a] --> \[... a a]
5. `swap` - 0x04 - Swaps the top two values on the stack - \[... a b] --> \[... b a]

### 1X series

1. `print.i64` - 0x10 - Prints the top value of the stack as i64 integer

### 2X series

1. `add` - 0x20 - Pops top 2 u64 values from the stack and pushes the addition of them on top of the stack - \[... a b] --> \[... a+b]
2. `sub` - 0x21 - Pops top 2 u64 values from the stack and pushes the subtraction of them on top of the stack - \[... a b] --> \[... a-b]
3. `mul` - 0x22 - Pops top 2 u64 values from the stack and pushes the multiplication of them on top of the stack - \[... a b] --> \[... a*b]

