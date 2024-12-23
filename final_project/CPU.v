// Your code
module CPU(clk,
            rst_n,
            // For mem_D (data memory)
            wen_D,
            addr_D,
            wdata_D,
            rdata_D,
            // For mem_I (instruction memory (text))
            addr_I,
            rdata_I);

    input         clk, rst_n ;
    // For mem_D
    output        wen_D  ;
    output [31:0] addr_D ;
    output [31:0] wdata_D;
    input  [31:0] rdata_D;
    // For mem_I
    output [31:0] addr_I ;
    input  [31:0] rdata_I;

    //---------------------------------------//
    // Do not modify this part!!!            //
    // Exception: You may change wire to reg //
    reg    [31:0] PC          ;              //
    reg    [31:0] PC_nxt      ;              //
    reg           regWrite    ;              //
    reg    [ 4:0] rs1, rs2, rd;              //
    wire   [31:0] rs1_data    ;              //
    wire   [31:0] rs2_data    ;              //
    reg    [31:0] rd_data     ;              //
    //---------------------------------------//

    // Todo: other wire/reg

    reg [31:0] instruction;
    reg [31:0] alu_result;

    reg        wen_D_reg;
    reg [31:0] addr_D_reg;
    reg [31:0] wdata_D_reg;

    reg [31:0] imm;
    reg [ 6:0] opcode;
    reg [ 2:0] funct3;
    reg [ 6:0] funct7;

    reg         mulDiv_valid;
    wire        mulDiv_ready;
    reg  [ 1:0] mulDiv_mode;
    reg  [31:0] mulDiv_in_A;
    reg  [31:0] mulDiv_in_B;
    wire [63:0] mulDiv_out;

    //---------------------------------------//
    // Do not modify this part!!!            //
    reg_file reg0(                           //
        .clk(clk),                           //
        .rst_n(rst_n),                       //
        .wen(regWrite),                      //
        .a1(rs1),                            //
        .a2(rs2),                            //
        .aw(rd),                             //
        .d(rd_data),                         //
        .q1(rs1_data),                       //
        .q2(rs2_data));                      //
    //---------------------------------------//

    // Todo: any combinational/sequential circuit

    assign wen_D = wen_D_reg;
    assign addr_D = addr_D_reg;
    assign wdata_D = wdata_D_reg;
    assign addr_I = PC;

    mulDiv mulDiv0(
        .clk(clk),
        .rst_n(rst_n),
        .valid(mulDiv_valid),
        .ready(mulDiv_ready),
        .mode(mulDiv_mode),
        .in_A(mulDiv_in_A),
        .in_B(mulDiv_in_B),
        .out_data(mulDiv_out)
    );

    always @(*) begin
        instruction = rdata_I;
        alu_result = 0;
        imm = 0;

        addr_D_reg = 0;
        wdata_D_reg = 0;
        wen_D_reg = 0;

        rd_data = 0;
        regWrite = 0;
        PC_nxt = PC + 4;

        opcode = instruction[6:0];
        rs1 = instruction[19:15];
        rs2 = instruction[24:20];
        rd = instruction[11:7];
        funct3 = instruction[14:12];
        funct7 = instruction[31:25];

        mulDiv_valid = 0;
        mulDiv_in_A = rs1_data;
        mulDiv_in_B = rs2_data;
        mulDiv_mode = 0;

        case (opcode)
            // R-type instructions: add, sub, mul, div, remu
            7'b0110011: begin
                case (funct7)
                    7'b0000000: rd_data = (funct3 == 000) ? rs1_data + rs2_data : 0; // ADD
                    7'b0100000: rd_data = (funct3 == 000) ? rs1_data - rs2_data : 0; // SUB
                    7'b0000001: begin
                        if (mulDiv_ready) begin
                            PC_nxt = PC + 4;
                            regWrite = 1;
                        end else begin
                            PC_nxt = PC;
                            regWrite = 0;
                        end
                        mulDiv_valid = 1;
                        case (funct3)
                            3'b000: begin
                                // $display("I'm MULing");
                                mulDiv_mode = 0;
                                rd_data = mulDiv_out[31:0];
                            end
                            3'b101: begin
                                mulDiv_mode = 1;
                                rd_data = mulDiv_out[31:0];
                            end
                            3'b111: begin
                                mulDiv_mode = 2;
                                rd_data = mulDiv_out[63:32];
                            end
                        endcase
                    end
                endcase
                regWrite = 1;
            end

            // I-type instructions: addi, slli, srli, srai, slti
            7'b0010011: begin
                imm = {{20{instruction[31]}}, instruction[31:20]};
                case (funct3)
                    3'b000: rd_data = rs1_data + imm; // ADDI
                    3'b001: rd_data = (funct7 == 7'b0000000) ? rs1_data << imm[4:0] : 0; // SLLI
                    3'b101: begin
                        if (funct7 == 7'b0000000) begin
                            rd_data = rs1_data >> imm[4:0]; // SRLI
                        end else if (funct7 == 7'b0100000) begin
                            rd_data = $signed(rs1_data) >>> imm[4:0]; // SRAI
                        end
                    end
                    3'b010: rd_data = ($signed(rs1_data) < $signed(imm)) ? 1 : 0; // SLTI
                endcase
                regWrite = 1;
            end

            // I-type instructions: lw
            7'b0000011: begin
                imm = {{20{instruction[31]}}, instruction[31:20]};
                case (funct3)
                    3'b010: alu_result = rs1_data + imm; // LW
                    default: alu_result = 0;
                endcase
                addr_D_reg = alu_result;
                rd_data = rdata_D;
                regWrite = 1;
            end

            // B-type instructions: beq, bne, bge, blt
            7'b1100011: begin
                case (funct3)
                    3'b000: alu_result = (rs1_data == rs2_data) ? 1 : 0; // BEQ
                    3'b001: alu_result = (rs1_data != rs2_data) ? 1 : 0; // BNE
                    3'b101: alu_result = ($signed(rs1_data) >= $signed(rs2_data)) ? 1 : 0; // BGE
                    3'b100: alu_result = ($signed(rs1_data) < $signed(rs2_data)) ? 1 : 0; // BLT
                    default: alu_result = 0;
                endcase
                if (alu_result) begin
                    imm = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
                    PC_nxt = PC + imm;
                end
            end

            // S-type instructions: sw
            7'b0100011: begin
                imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
                case (funct3)
                    3'b010: alu_result = rs1_data + imm; // SW
                    default: alu_result = 0;
                endcase
                addr_D_reg = alu_result;
                wdata_D_reg = rs2_data;
                wen_D_reg = 1;
            end

            // J-type instructions: jal
            7'b1101111: begin
                imm = {{20{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
                alu_result = PC + imm; // JAL
                PC_nxt = alu_result;
                rd_data = PC + 4;
                regWrite = 1;
            end

            // I-type instructions: jalr
            7'b1100111: begin
                imm = {{20{instruction[31]}}, instruction[31:20]};
                case (funct3)
                    3'b000: alu_result = (rs1_data + imm) & ~1; // JALR
                    default: alu_result = 0;
                endcase
                PC_nxt = alu_result;
                rd_data = PC + 4;
                regWrite = 1;
            end

            // U-type instructions: auipc
            7'b0010111: begin
                imm = {{instruction[31:12], 12'b0}};
                rd_data = PC + imm; // AUIPC
                regWrite = 1;
            end

            // U-type instructions: lui
            7'b0110111: begin
                imm = {{instruction[31:12], 12'b0}};
                rd_data = imm; // LUI
                regWrite = 1;
                // $display("Lui Out = %h", rd_data);
            end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            PC <= 32'h00010000; // Do not modify this value!!!
        end
        else begin
            PC <= PC_nxt;
            // $display("Opcode: %b, Funct3: %b, Funct7: %b, RS1: %h, RS2: %h, Imm: %h", opcode, funct3, funct7, rs1_data, rs2_data, imm);
            // $display("Out = %h", rd_data);
        end
    end
endmodule

// Do not modify the reg_file!!!
module reg_file(clk, rst_n, wen, a1, a2, aw, d, q1, q2);

    parameter BITS = 32;
    parameter word_depth = 32;
    parameter addr_width = 5; // 2^addr_width >= word_depth

    input clk, rst_n, wen; // wen: 0:read | 1:write
    input [BITS-1:0] d;
    input [addr_width-1:0] a1, a2, aw;

    output [BITS-1:0] q1, q2;

    reg [BITS-1:0] mem [0:word_depth-1];
    reg [BITS-1:0] mem_nxt [0:word_depth-1];

    integer i;

    assign q1 = mem[a1];
    assign q2 = mem[a2];

    always @(*) begin
        for (i=0; i<word_depth; i=i+1)
            mem_nxt[i] = (wen && (aw == i)) ? d : mem[i];
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem[0] <= 0;
            for (i=1; i<word_depth; i=i+1) begin
                case(i)
                    32'd2: mem[i] <= 32'hbffffff0;
                    32'd3: mem[i] <= 32'h10008000;
                    default: mem[i] <= 32'h0;
                endcase
            end
        end
        else begin
            mem[0] <= 0;
            for (i=1; i<word_depth; i=i+1)
                mem[i] <= mem_nxt[i];
        end
    end
endmodule

module mulDiv(clk, rst_n, valid, ready, mode, in_A, in_B, out_data);
    // Todo: your HW2

    input         clk;
    input         rst_n;
    input         valid;
    output        ready;
    input  [ 1:0] mode;
    input  [31:0] in_A;
    input  [31:0] in_B;
    output [63:0] out_data;

    reg  [ 1:0] cur_state, next_state;
    reg  [ 4:0] cur_counter, next_counter;
    reg  [63:0] cur_reg, next_reg;
    wire [31:0] cur_in;
    reg         cur_ready, next_ready;

    reg  [32:0] temp;
    reg         mark;

    assign out_data = cur_reg;
    assign ready = cur_ready;
    assign cur_in = (cur_state == 0 && valid) ? in_B : cur_in;

    always @(*) begin
        // $display("State = %d, Mode = %d, Count = %d, Valid = %d", cur_state, mode, cur_counter, valid);
	    // $display("Cur in = %b", cur_in);
        // $display("Cur_reg = %b", cur_reg);
        temp = 0;
        mark = 0;
        case (cur_state)
            0: begin // IDLE
                next_ready = 0;
                if (!valid) begin
                    next_state = 0;
                    next_reg = 0;
                end else begin
                    case (mode)
                        0: begin
                            next_state = 1;
                            next_reg = {{32{1'b0}}, in_A};
                        end
                        1, 2: begin
                            next_state = 2;
                            next_reg = {{32{1'b0}}, in_A, 1'b0};
                        end
                        default: begin
                            next_state = 0;
                            next_reg = 0;
                        end
                    endcase
                end
            end
            1: begin // MUL
                if (cur_counter == 31) begin
                    next_ready = 1;
                    next_state = 3;
                end else begin
                    next_ready = 0;
                    next_state = 1;
                end
                temp = (cur_reg[0] == 1) ? cur_reg[63:32] + cur_in : cur_reg[63:32];
                next_reg = {temp, cur_reg[31:1]};
            end
            2: begin // DIV, REMU
                mark = cur_reg[63:32] >= cur_in;
                temp = mark ? cur_reg[63:32] - cur_in : cur_reg[63:32];
                if (cur_counter == 31) begin
                    next_reg = mark ? {temp[31:0], cur_reg[30:0], 1'b1} : {temp[31:0], cur_reg[30:0], 1'b0};
                    next_ready = 1;
                    next_state = 3;
                end else begin
                    next_reg = mark ? {temp[30:0], cur_reg[31:0], 1'b1} : {temp[30:0], cur_reg[31:0], 1'b0};
                    next_ready = 0;
                    next_state = 2;
                end
            end
            3: begin // OUT
                next_state = 0;
                next_ready = 0;
                next_reg = cur_reg;
                // $display("Out for mulDiv = %h", cur_reg);
            end
            default: begin
                next_state = 0;
                next_ready = 0;
                next_reg = 0;
            end
        endcase
    end

    always @(*) begin
        if (cur_state == 1 || cur_state == 2) begin
            next_counter = cur_counter + 1;
        end else next_counter = 0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cur_state <= 0;
            cur_counter <= 0;
            cur_reg <= 0;
            cur_ready <= 0;
        end else begin
            cur_state <= next_state;
            cur_counter <= next_counter;
            cur_reg <= next_reg;
            cur_ready <= next_ready;
        end
    end
endmodule
