Kernel Migrations Format
===

The migrations format is kept as close to the original Kconfig format
as possible. Some changes were made to make it easier to parse. Below
are some examples of possible values.

```
CONFIG_ARCH_DEFCONFIG="arch/x86/configs/x86_64_defconfig"
CONFIG_SYSTEM_TRUSTED_KEYS=""
CONFIG_64BIT=n
CONFIG_X86=y
CONFIG_MMU=unset
```

All lines starting with a pound (`#`) will be skipped. In order to make
use of the normal 'unset' behaviour, use the magic value '`unset`' instead.
This will render a Kconfig line like `# CONFIG_MMU is not set`.
