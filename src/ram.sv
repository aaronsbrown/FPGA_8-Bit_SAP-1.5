module ram (
    input   logic clk,
    input   logic we, // RI
    // input   wire oe, //RO
    input   logic [3:0] address, // 4-bit address (16 bytes)  
    input   logic [7:0] data_in,
    output  logic [7:0] data_out
);

reg [7:0] ram [0:15] = '{
    8'h1F, // contents for addresses 0-3
    8'h4E,  
    8'hE0, 
    8'hFF, 
    8'h00, 
    8'h00, 
    8'h00,  
    8'h00,  // addresses 8-11
    8'h00, 
    8'h00, 
    8'h00, 
    8'h00, // addresses 12-15
    8'h00, 
    8'h0A, 
    8'h0F  
}; // 16 x 8-bit RAM

always @(posedge clk) begin
    if (we) begin
        ram[address] <= data_in; // Write data to RAM
    end
    // if (oe) begin
        data_out <= ram[address]; // Read data from RAM
    // end
end


integer i;
initial begin
  $display("Initializing RAM from program.hex");
//   $readmemh("program.hex", ram);
  for (i = 0; i < 16; i = i + 1)
    $display("RAM[%0d] = %02h", i, ram[i]);
end



endmodule
