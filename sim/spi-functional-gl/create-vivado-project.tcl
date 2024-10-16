# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2024 Anders <anders-code@users.noreply.github.com>

# source with vivado to create a project

set sim_dir  [file normalize "[info script]/.."]
set repo_dir [file normalize ${sim_dir}/../..]

set proj_name "project-[version -short]-sim-spi-functional-gl"
set proj_dir  "${sim_dir}/${proj_name}"

create_project -force ${proj_name} ${proj_dir}

set sources_1 [get_filesets "sources_1"]

add_files -norecurse -fileset ${sources_1} [list \
    [file normalize "${sim_dir}/primitives_behav.sv"] \
    [file normalize "${sim_dir}/sky130_fd_sc_hd.v"] \
    [file normalize "${sim_dir}/tt_um_anders_tt_6502.pnl.v"] \
    [file normalize "${repo_dir}/rtl/spi_sram_slave.sv"] \
]

set_property -obj ${sources_1} "include_dirs" ${repo_dir}
set_property -obj ${sources_1} "top" "cpu_6502"

set sim_utils_dir "${repo_dir}/sim/utils"

set sim_1 [get_filesets "sim_1"]
add_files -norecurse -fileset ${sim_1} [list \
    [file normalize "${sim_utils_dir}/tb_clkrst.sv"] \
    [file normalize "${sim_utils_dir}/tb_utils.sv"] \
    [file normalize "${sim_dir}/tb_spi_functional_gl.sv"] \
]
#    [file normalize "${sim_dir}/tb_spi_functional_behav.wcfg"] \

set_property -obj ${sim_1} "include_dirs" ${repo_dir}
set_property -obj ${sim_1} "verilog_define" "FUNCTIONAL=1 USE_POWER_PINS=1"
set_property -obj ${sim_1} "top" "tb_spi_functional_gl"
set_property -obj ${sim_1} "xsim.more_options" {\-testplusarg basedir=../../../../..}
