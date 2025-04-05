module ram (
    input   logic clk,
    input   logic we, // RI
    input   logic [3:0] address, // 4-bit address (16 bytes)  
    input   logic [7:0] data_in,
    output  logic [7:0] data_out
);

    // Declare the RAM register without an initializer
    reg [7:0] ram [0:15];
    
`ifndef SIMULATION
    // For synthesis (or non-simulation), initialize RAM with the hardcoded values.
    initial begin
        ram[0]  = 8'h1F;
        ram[1]  = 8'h4E;
        ram[2]  = 8'hE0;
        ram[3]  = 8'h86;
        ram[4]  = 8'hE0;
        ram[5]  = 8'h90;
        ram[6]  = 8'h00;
        ram[7]  = 8'h00;
        ram[8]  = 8'h00;
        ram[9]  = 8'h00;
        ram[10] = 8'h00;
        ram[11] = 8'h00;
        ram[12] = 8'h00;
        ram[13] = 8'h00;
        ram[14] = 8'h0A;
        ram[15] = 8'h0F;
    end
`endif
   
    always @(posedge clk) begin
        if (we) begin
            ram[address] <= data_in; // Write data to RAM
        end
        // if (oe) begin
            data_out <= ram[address]; // Read data from RAM
        // end
    end

    // Task to dump RAM contents
    task dump;
      integer j;
      begin
        for (j = 0; j < 16; j = j + 1) begin
          $display("RAM[%0d] = %02h", j, ram[j]);
        end
      end
    endtask

endmodule
