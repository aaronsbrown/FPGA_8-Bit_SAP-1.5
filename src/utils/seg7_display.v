module seg7_display (
    input clk,
    input reset,
    input [7:0] number,
    output reg [6:0] seg7,
    output reg [3:0] select
);
    
    reg[3:0] hundreds, tens, ones;
    wire [6:0] seg_ones, seg_tens, seg_hundreds;
    reg [1:0] mux_counter;

    digit_to_7seg u_ones (
        .digit(ones),
        .seg7(seg_ones)
    );

    digit_to_7seg u_tens (
        .digit(tens),
        .seg7(seg_tens)
    );

    digit_to_7seg u_hundreds (
        .digit(hundreds),
        .seg7(seg_hundreds)
    );

    wire slow_clk;
    clock_divider #(
        .DIV_FACTOR(50_000)
    ) clk_div (
        .reset(reset),
        .clk_in(clk),
        .clk_out(slow_clk)
    );

    //  COMBINATIONAL: Digit extraction
    always @(*) begin
        hundreds = number / 100;
        tens = (number - hundreds * 100) / 10;
        ones = number - hundreds * 100 - tens * 10;    
    end
    
    // SEQUENTIAL: Multiplexing
    always @(posedge slow_clk or posedge reset) begin
        if (reset) begin
            mux_counter <= 2'b00;
        end else begin
            if (mux_counter == 2'b10) begin
                mux_counter <= 2'b00;
            end else begin
                mux_counter <= mux_counter + 1;
            end
        end
    end

    // COMBINATIONAL: 7-segment display
    always @(*) begin
        case (mux_counter) 
            2'b00: begin
                select = ~4'b0001;
                seg7 = seg_ones;
            end
            
            2'b01: begin
                select = ~4'b0010;
                seg7 = seg_tens;
            end

            2'b10: begin
                select = ~4'b0100;
                seg7 = seg_hundreds;
            end

            default: begin
                select = 4'b1111;
                seg7 = 7'b1111111;
            end
        endcase
    end

endmodule
