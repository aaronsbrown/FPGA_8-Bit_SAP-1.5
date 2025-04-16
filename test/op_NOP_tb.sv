`timescale 1ns/1ps
import test_utils_pkg::*;
import arch_defs_pkg::*; 

module computer_tb;

    localparam string HEX_FILE = "../fixture/NOP.hex";
    
    reg clk;
    reg reset;
    wire [DATA_WIDTH-1:0] out_val; 
    wire [2:0] cpu_flags_out;
  
    computer uut (
            .clk(clk),
            .reset(reset),
            .out_val(out_val)
    );

    // Clock generation: 10ns period (5ns high, 5ns low)
    initial begin clk = 0; forever #5 clk = ~clk; end

    // Testbench stimulus
    initial begin
        
        $dumpfile("waveform.vcd");
        $dumpvars(0, computer_tb);


        //         # Address | Instruction | Opcode | Comment
        // #----------------------------------------------------
        // # 0x0     | LDI A, #5   |  85    | A = 5 (0101)
        // # 0x1     | STA A, 0xE  |  7E    | RAM[0xE] = 5
        // # 0x2     | LDI A, #3   |  83    | A = 3 (0011)
        // # 0x3     | STA A, 0xD  |  7D    | RAM[0xD] = 3
        // # 0x4     | SUB A, 0xE  |  4E    | A = A - RAM[0xE] = 3 - 5 = -2 (1110)
        // #         |             |        | Sets Flags: Z=0, C=0 (borrow), N=1
        // # 0x5     | LDB 0xD     |  2D    | B = RAM[0xD] = 3 (0011)
        // # 0x6     | NOP         |  00    | The instruction under test.
        // # 0x7     | HLT         |  FF    | Stop execution.
        // # ...     |             |        |
        // # 0xD     | DATA        |  00    | Will hold 3 after STA
        // # 0xE     | DATA        |  00    | Will hold 5 after STA
        // # 0xF     | DATA        |  00    | Unused
        $display("--- Loading hex file: %s ---", HEX_FILE);
        $readmemh(HEX_FILE, uut.u_ram.mem);
        uut.u_ram.dump();
        
        reset_and_wait(0);
        run_until_halt(100);

            // 1. Check PC: Should be at address 8 (after HLT at address 7)
        inspect_register(uut.u_program_counter.counter_out, 8, "PC", ADDR_WIDTH);

        // 2. Check Register A: Should be -2 (0xE) from the SUB 3, 5 instruction
        inspect_register(uut.u_register_A.latched_data, 8'hFE, "A", DATA_WIDTH); // FE is two's complement -2

        // 3. Check Register B: Should be 3 (0x03) from the LDB 0xD instruction *before* NOP
        inspect_register(uut.u_register_B.latched_data, 8'h03, "B", DATA_WIDTH);

        // TODO
        // 4. Check Flags (CRITICAL - Requires Flags Register Implementation):
        //    The SUB instruction (3 - 5) should result in:
        //    - Zero Flag (Z) = 0
        //    - Carry Flag (C) = 0 (because Borrow occurred for 3 < 5)
        //    - Negative Flag (N) = 1 (because result -2 is negative)
        //    The LDB instruction *might* affect Z and N depending on your design choice.
        //    The NOP instruction should *preserve* the state left by LDB (or SUB if LDB doesn't affect flags).
        $display("Checking Flags (Requires Flags Register implementation for accuracy)...");
        // Assuming LDB does *not* affect flags, the state should be from SUB 3,5:
        // Replace uut.flag_out_X with the actual outputs from your flags register
        // pretty_print_assert_vec(cpu_flags_out[0], 1'b0, "Zero Flag (Z)");
        // pretty_print_assert_vec(cpu_flags_out[1], 1'b0, "Carry Flag (C)");
        // pretty_print_assert_vec(cpu_flags_out[2], 1'b1, "Negative Flag (N)");
        // $display("NOTE: Flag verification requires Flags Register and update_flags logic. Specify LDA/LDB flag effect.");


        // 5. Check RAM[0xD]: Should contain 3 (0x03) from the second STA
        pretty_print_assert_vec(uut.u_ram.mem[13], 8'h03, "RAM[0xD]");

        // 6. Check RAM[0xE]: Should contain 5 (0x05) from the first STA
        pretty_print_assert_vec(uut.u_ram.mem[14], 8'h05, "RAM[0xE]");

        $display("\033[0;32mLDB instruction test completed successfully.\033[0m");
        $finish;
    end

endmodule