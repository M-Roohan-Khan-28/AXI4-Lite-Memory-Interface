# Provenance

Source repository: https://github.com/rouhan28may-droid/riscv-axi-soc
Source commit: `ceacccb687b39af045431f2ce4d1205276780b6a`

The table lists exact byte-for-byte copies. The integration top, two new direct harnesses, integration harness, launchers, and documentation were added only in this standalone repository. No extracted RTL was corrected or modified. The original SoC repository was cloned read-only.

| Original path | Standalone path | SHA-256 |
| --- | --- | --- |
| `docs/MEMORY_MAP.md` | `historical_docs/MEMORY_MAP.md` | `b3ebbf63c31ee80a4ce89aedc75daf7e8b92338de34a0f503b8f520f336fd3ab` |
| `logs/axi_master_test.compile.log` | `historical_logs/axi_master_test.compile.log` | `7735f77a1ee8c419bf0627447c9de388b3fae7d5956304518db936bbb1bf0467` |
| `logs/axi_master_test.log` | `historical_logs/axi_master_test.log` | `53e35863ac1278d970507373615af35292865cdd3d55dfa46cb1877deedc565e` |
| `logs/axi_reset_test.compile.log` | `historical_logs/axi_reset_test.compile.log` | `6c444c65d194bef2c66e14baa8437d90eceb11fe814ee76d3796778b92efec57` |
| `logs/axi_reset_test.log` | `historical_logs/axi_reset_test.log` | `41919069c576dad3dfaecf3383c2df690931560b2c6ed8fa5a7a25e2d3dfe808` |
| `logs/axi_slave_test.compile.log` | `historical_logs/axi_slave_test.compile.log` | `f5349e86d08097226a04324d634b84ed7d2cdc4fffd0770ce6d1fc30bd838efd` |
| `logs/axi_slave_test.log` | `historical_logs/axi_slave_test.log` | `b47da4a25eabd754b63a79196f13ddbf13d10feddd858453e1e3f61bd0d574d6` |
| `logs/sram_test.compile.log` | `historical_logs/sram_test.compile.log` | `13615d57efa8d5b2f06076bba2a4d5063a91ee82135360329e82245eb64c86ab` |
| `logs/sram_test.log` | `historical_logs/sram_test.log` | `4acad0d37df542498a16195d6cc80cb1be2cec8fecbfc875fc38db3abb66b9ee` |
| `rtl/axi/axi_lite_master.sv` | `rtl/axi/axi_lite_master.sv` | `3c27fd2b8b898523cb4784e00e9c0872486f33ee36ba96bddf499118bb74965f` |
| `rtl/axi/axi_lite_slave.sv` | `rtl/axi/axi_lite_slave.sv` | `ea2c83602f2056ba779e1270749181e0e5aeb415a5043b90e6ca29ee9906005e` |
| `rtl/memory/sram.sv` | `rtl/memory/sram.sv` | `d42677005b233ebffb7a25b2d138b83a4a3ec3fc7891c9657c82988306165f3a` |
| `tb/axi_delay.sv` | `tb/legacy/axi_delay.sv` | `c829215b17ac8bae8d7c823e2e81edc78ca7d97bdc9739068b4beb78766b3059` |
| `tb/axi_lite_if.sv` | `rtl/axi/axi_lite_if.sv` | `463f775261a7489ae6b8a3481930b4be2aae290f7ef3a14f0892b1e59483a0d9` |
| `tb/axi_protocol_checker.sv` | `tb/legacy/axi_protocol_checker.sv` | `43555cb08791bbf54ced881eb8f54e9f32e3854185f9d1ea410b27442a261941` |
| `tb/tests/axi_master_test.sv` | `tb/legacy/axi_master_test.sv` | `47ad36042d5dc0e3438b5a05f76b7e8a9cc32b343901e2306a1007b31cb983a3` |
| `tb/tests/axi_reset_test.sv` | `tb/legacy/axi_reset_test.sv` | `7b7800110628c9673f9484fe3ca0e2ab8ba4281e356139a4185f8a827f341486` |
| `tb/tests/axi_slave_test.sv` | `tb/legacy/axi_slave_test.sv` | `7df791bac5e7961668f9109f83c40041ad565c051ee6864f82c68eb2d0135653` |
| `tb/tests/sram_test.sv` | `tb/legacy/sram_test.sv` | `f708cee1c373c0288f54df58d2818747d0d7fef6c67c3b3f96216481538c5e9d` |

The SoC source snapshot has no LICENSE, COPYING, NOTICE, or AUTHORS file. Existing in-file comments and any headers remain intact. The source commit records `roohan <rouhan28may@gmail.com>` as its last author for the copied core files. No new blanket licence is assigned to copied material; see `LICENSE_STATUS.md`.
