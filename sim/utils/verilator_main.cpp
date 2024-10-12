#include <stdint.h>
#include <stdlib.h>
#include <signal.h>

#include "verilated.h"

// define with -D
#if !defined(VTB)
    #define VTB Vtb
#endif

#if !defined(RESET_CYCLES)
    #define RESET_CYCLES 5
#endif

#if !defined(MAX_CYCLES)
    #define MAX_CYCLES UINT64_MAX
#endif

#if !defined(TIME_INCREMENT)
    #define TIME_INCREMENT 5000
#endif

#define Q(a) #a
#define HEADER(a) Q(a.h)

#include HEADER(VTB)

static volatile int die = 0;

void trap_int(int)
{
    die = 1;
}

int main(int argc, char **argv)
{
    struct sigaction act;
    act.sa_handler = trap_int;
    sigaction(SIGINT, &act, 0);

    VerilatedContext *context = new VerilatedContext();

    VTB *tb = new VTB(context);

    Verilated::commandArgs(argc, argv);

#if VM_TRACE
    Verilated::traceEverOn(true);
#endif

    uint64_t cycles = 0;

    // start with clock and reset low
    // raise reset after 4 (RESET_CYCLES-1) clocks on the negedge
    // drop reset after 5 (RESET_CYCLES) clocks on the negedge
    // - no clock edge @0
    // - first clock rising edge is @ 10 ns
    // - the n-th clock edge is @ (n*10) ns
    // - first clock rising edge with reset is @ 50ns
    // - first clock rising edge after reset is @ 100ns

    tb->rst = 0;
    tb->clk = 0;

    tb->eval();
    context->timeInc(TIME_INCREMENT);

    while (!die && !context->gotFinish() && cycles < RESET_CYCLES-1)
    {
        tb->clk = 0;
        tb->eval();
        context->timeInc(TIME_INCREMENT);

        tb->clk = 1;
        tb->eval();
        context->timeInc(TIME_INCREMENT);
        ++cycles;
    }

    tb->rst = 1;

    while (!die && !context->gotFinish() && cycles < RESET_CYCLES*2-1)
    {
        tb->clk = 0;
        tb->eval();
        context->timeInc(TIME_INCREMENT);

        tb->clk = 1;
        tb->eval();
        context->timeInc(TIME_INCREMENT);
        ++cycles;
    }

    tb->rst = 0;

    while (!die && !context->gotFinish() && cycles < MAX_CYCLES)
    {
        tb->clk = 0;
        tb->eval();
        context->timeInc(TIME_INCREMENT);

        tb->clk = 1;
        tb->eval();
        context->timeInc(TIME_INCREMENT);
        ++cycles;
    }

    tb->final();

    context->statsPrintSummary();

    delete tb;
    delete context;

    return 0;
}

