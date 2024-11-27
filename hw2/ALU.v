module ALU (
    input           clk,
    input           rst_n,
    input           valid,
    input   [31:0]  in_A,
    input   [31:0]  in_B,
    input   [3:0]   mode,
    output reg      ready,
    output reg [63:0] out_data
);

// ===============================================
//                    wire & reg
// ===============================================
reg [63:0] product;
reg [31:0] dividend, divisor;
reg [31:0] quotient, remainder;
reg [5:0] cycle_count;
reg mul_active, div_active;

// ===============================================
//                   combinational
// ===============================================
always @(*) begin
    case (mode)
        4'b0000: out_data = {32'd0, in_A + in_B};       // Addition
        4'b0001: out_data = {32'd0, in_A - in_B};       // Subtraction
        4'b0010: out_data = {32'd0, in_A & in_B};       // AND
        4'b0011: out_data = {32'd0, in_A | in_B};       // OR
        4'b0100: out_data = {32'd0, in_A ^ in_B};       // XOR
        4'b0101: out_data = {63'd0, (in_A == in_B)};    // Equality
        4'b0110: out_data = {63'd0, (in_A >= in_B)};    // Greater or Equal
        4'b0111: out_data = (in_B < 32) ? {32'd0, in_A >> in_B} : 64'd0; // Logical Right Shift
        4'b1000: out_data = (in_B < 32) ? {32'd0, in_A << in_B} : 64'd0; // Logical Left Shift
        default: out_data = 64'd0;                     // Undefined mode
    endcase
end

// ===============================================
//                    sequential
// ===============================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ready <= 1'b0;
        mul_active <= 1'b0;
        div_active <= 1'b0;
        cycle_count <= 6'd0;
        product <= 64'd0;
        quotient <= 32'd0;
        remainder <= 32'd0;
        out_data <= 64'd0;
    end else if (valid) begin
        case (mode)
            4'b1001: begin  // Multiplication
                mul_active <= 1'b1;
                product <= in_A * in_B;
                cycle_count <= 6'd1;  // Adjusted cycle count for timing
                ready <= 1'b0;
            end
            4'b1010: begin  // Division
                div_active <= 1'b1;
                dividend <= in_A;
                divisor <= in_B;
                quotient <= 32'd0;
                remainder <= 32'd0;
                cycle_count <= 6'd32;  // Assume 32 cycles for division
                ready <= 1'b0;
            end
            default: ready <= 1'b1;  // Immediate response for other operations
        endcase
    end else if (mul_active) begin
        if (cycle_count > 0) begin
            cycle_count <= cycle_count - 1;
        end else begin
            mul_active <= 1'b0;
            ready <= 1'b1;
            out_data <= product;  // Output multiplication result
        end
    end else if (div_active) begin
        if (cycle_count > 0) begin
            cycle_count <= cycle_count - 1;
            if (dividend >= divisor) begin
                dividend <= dividend - divisor;
                quotient <= quotient + 1;
            end
        end else begin
            div_active <= 1'b0;
            ready <= 1'b1;
            out_data <= {dividend, quotient};  // Output division result
        end
    end
end

endmodule
