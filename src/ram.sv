import arch_defs_pkg::*;

module ram (
    input   logic clk,
    input   logic we,
    input   logic [ADDR_WIDTH-1:0] address, // 4-bit address (16 bytes)  
    input   logic [DATA_WIDTH-1:0] data_in,
    output  logic [DATA_WIDTH-1:0] data_out
);

    // Declare the RAM register without an initializer
    logic [DATA_WIDTH-1:0] mem [0: RAM_DEPTH - 1]; 
    
    logic [DATA_WIDTH-1: 0] data_out_i;

    always_ff @(posedge clk) begin
        if (we) begin
            mem[address] <= data_in; // Write data to RAM
        end
        data_out_i <= mem[address]; // Read data from RAM       
    end

    assign data_out = data_out_i;

    // Task to dump RAM contents
    task dump;
      integer j;
      begin
        $display("--- RAM Content Dump ---");
        for (j = 0; j < RAM_DEPTH; j = j + 1) begin
          $display("RAM[%0d] = %02h", j, mem[j]);
        end
        $display("--- End RAM Dump ---");
      end
    endtask

`ifndef SIMULATION
    initial begin
        // Synthesis tool reads this file during compilation
        $readmemh("fixture/default_program_synth.hex", mem);
    end
`endif

endmodule
