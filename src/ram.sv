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
    // For synthesis (or non-simulation), initialize RAM with the hardcoded values.
    initial begin
        mem[0]  = 8'h1F;
        mem[1]  = 8'h4E;
        mem[2]  = 8'hE0;
        mem[3]  = 8'h86;
        mem[4]  = 8'hE0;
        mem[5]  = 8'h90;
        mem[6]  = 8'h00;
        mem[7]  = 8'h00;
        mem[8]  = 8'h00;
        mem[9]  = 8'h00;
        mem[10] = 8'h00;
        mem[11] = 8'h00;
        mem[12] = 8'h00;
        mem[13] = 8'h00;
        mem[14] = 8'h0A;
        mem[15] = 8'h0F;
    end
`endif

endmodule
