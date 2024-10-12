// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Anders <anders-code@users.noreply.github.com>

`ifndef UTILS_TB_ASSERT_VH
`define UTILS_TB_ASSERT_VH

`define tb_assert(a) \
    assert(a) tb_asspass(`"a`", `__FILE__, `__LINE__); else \
              tb_assfail(`"a`", `__FILE__, `__LINE__)

`endif // UTILS_TB_ASSERT_VH
