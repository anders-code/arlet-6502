# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2024 Anders <anders-code@users.noreply.github.com>

# source with vivado to create a project

set sim_dir  [file normalize "[info script]/.."]
set repo_dir [file normalize ${sim_dir}/../..]

set proj_name "project-[version -short]-sim-wait-state"
set proj_dir  "${sim_dir}/${proj_name}"

create_project -force ${proj_name} ${proj_dir}

set sources_1 [get_filesets "sources_1"]

add_files -norecurse -fileset ${sources_1} [list \
    [file normalize "${repo_dir}/rtl/alu_6502.v"] \
    [file normalize "${repo_dir}/rtl/cpu_6502.v"] \
]

set_property -obj ${sources_1} "include_dirs" ${repo_dir}
set_property -obj ${sources_1} "top" "cpu_6502"

set sim_utils_dir "${repo_dir}/sim/utils"

set sim_1 [get_filesets "sim_1"]
add_files -norecurse -fileset ${sim_1} [list \
    [file normalize "${sim_utils_dir}/tb_clkgen.sv"] \
    [file normalize "${sim_utils_dir}/tb_utils.sv"] \
    [file normalize "${sim_dir}/tb_wait_state.sv"] \
    [file normalize "${sim_dir}/tb_wait_state_behav.wcfg"] \
]

set_property -obj ${sim_1} "include_dirs" ${repo_dir}
set_property -obj ${sim_1} "verilog_define" "SIM=1"
set_property -obj ${sim_1} "top" "tb_wait_state"
set_property -obj ${sim_1} "xsim.more_options" {\-testplusarg basedir=../../../../..}
