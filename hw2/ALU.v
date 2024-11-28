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
//                    Registers
// ===============================================
reg [31:0] temp;
reg [63:0] out;
reg [64:0] temp_sum;
reg [63:0] temp_dif;
reg [63:0] product;
reg [63:0] remainder;
reg [31:0] divisor;
reg [31:0] multiplicand;
reg [5:0]  count;
reg mul_active, div_active;

// ===============================================
//                Combinational Logic
// ===============================================
always @(*) begin
    out = 64'd0;
    case (mode)
        4'b0000: begin
            temp = in_A + in_B;
            if (!(in_A[31] ^ in_B[31]) && (in_A[31] ^ temp[31])) begin
                out = {32'd0, (in_A[31] ? 32'h80000000 : 32'h7FFFFFFF)};
            end else begin
                out = {32'd0, temp};
            end
        end
        4'b0001: begin
            temp = in_A - in_B;
            if ((in_A[31] ^ in_B[31]) && (in_A[31] ^ temp[31])) begin
                out = {32'd0, (in_A[31] ? 32'h80000000 : 32'h7FFFFFFF)};
            end else begin
                out = {32'd0, temp};
            end
        end
        4'b0010: out = {32'd0, in_A & in_B};
        4'b0011: out = {32'd0, in_A | in_B};
        4'b0100: out = {32'd0, in_A ^ in_B};
        4'b0101: out = {63'd0, (in_A == in_B)};
        4'b0110: out = {63'd0, ($signed(in_A) >= $signed(in_B))};
        4'b0111: out = {32'd0, in_A >> in_B};
        4'b1000: out = {32'd0, in_A << in_B};
    endcase
end

// ===============================================
//                Sequential Logic
// ===============================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ready <= 1'b0;
        mul_active <= 1'b0;
        div_active <= 1'b0;
        out_data <= 64'd0;
        count <= 6'd0;
    end else if (ready) begin
        ready <= 1'b0;
        mul_active <= 1'b0;
        div_active <= 1'b0;
        count <= 6'd0;
    end else if (valid) begin
        case (mode)
            4'b1001: begin
                mul_active <= 1'b1;
                multiplicand <= in_A;
                if (in_B[0] == 1'b1) begin
                    product <= {in_A, in_B} >> 1;
                end else begin
                    product <= {32'd0, in_B} >> 1;
                end
            end
            4'b1010: begin
                div_active <= 1'b1;
                divisor <= in_B;
                if (!in_A[31] || in_B > 32'd1) begin
                    remainder <= {32'd0, in_A} << 2;
                end else begin
                    remainder <= {31'd0, in_A[30:0], 2'b00};
                end
            end
        endcase
        if (mode <= 8) begin
            out_data <= out;
            ready <= 1'b1;
        end
    end else if (mul_active) begin
        if (count < 33) begin
            if (product[0] == 1'b1) begin
                temp_sum = product + {multiplicand, 32'd0};
                product <= temp_sum[64:1];
            end else begin
                product <= product >> 1;
            end
            count <= count + 1;
        end else begin
            mul_active <= 1'b0;
        end
        if (count == 31) begin
            out_data <= product;
            ready <= 1'b1;
        end
    end else if (div_active) begin
        if (count < 33) begin
            if (remainder < {divisor, 32'd0}) begin
                temp_dif = remainder;
                remainder <= remainder << 1;
            end else begin
                temp_dif = remainder - {divisor, 32'd0};
                remainder <= {remainder - {divisor, 32'd0}, 1'b1};
            end
            count <= count + 1;
        end else begin
            div_active <= 1'b0;
        end
        if (count == 31) begin
            out_data <= {temp_dif[63:32], remainder[31:0]};
            ready <= 1'b1;
        end
    end
end

endmodule
