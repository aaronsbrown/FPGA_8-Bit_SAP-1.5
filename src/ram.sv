module ram (
    input   wire clk,
    input   wire we, // RI
    input   wire oe, //RO
    input   wire [3:0] address, // 4-bit address (16 bytes)  
    input   wire [7:0] data_in,
    output  wire [7:0] data_out
);

reg [7:0] ram [0:15]; // 16 x 8-bit RAM
reg [7:0] data_out_reg;

assign data_out = (oe) ? data_out_reg : 8'bz; // High-Z when not reading

always @(posedge clk) begin
    if (we) begin
        ram[address] <= data_in; // Write data to RAM
    end
    if (oe) begin
        data_out_reg <= ram[address]; // Read data from RAM
    end
end

initial begin
    ram[0] = 8'b00011111; // LDA Mem[15]
    ram[15] = 8'b01010101; // 55
end

endmodule
