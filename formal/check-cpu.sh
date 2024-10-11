#!/bin/sh -x

# usage: check.sh <git hash of gold> [<git hash of gate>]

cd "${0%/*}"

mkdir gold gate

get() {
    local rev="$1"
    local dest="$2"
    shift 2
    while [ -n "$1" ]; do
        git show "${rev}:$1" > "${dest}" && break
        shift
    done
}

get_pair() {
    local old="$1"
    local new="$2"
    local dest="$3"
    shift 3
    get "${old}" "gold/${dest}" "$@"
    if [ -n "${new}" ]; then
        get "${new}" "gate/${dest}" "$@"
    else
        cp -f "$1" "gate/${dest}"
    fi
}

get_pair "$1" "$2" "cpu_6502.sv" \
    "../rtl/cpu_6502.sv" \
    "../rtl/cpu_6502.v" \
    "../cpu.v"

get_pair "$1" "$2" "alu_6502.sv" \
    "../rtl/alu_6502.sv" \
    "../rtl/alu_6502.v" \
    "../ALU.v"

get_pair "$1" "$2" "config.vh" "../rtl/config.vh"
get_pair "$1" "$2" "async_reset.vh" "../rtl/async_reset.vh"
get_pair "$1" "$2" "timescale.vh" "../rtl/timescale.vh"

sed -i -e 's/module cpu(/module cpu_6502(/' gold/cpu_6502.sv gate/cpu_6502.sv
sed -i -e 's/ALU ALU(/alu_6502 alu_inst(/'  gold/cpu_6502.sv gate/cpu_6502.sv
sed -i -e 's/module ALU(/module alu_6502(/' gold/alu_6502.sv gate/alu_6502.sv

eqy -f check-cpu.eqy
