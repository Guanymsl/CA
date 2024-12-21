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
    wire   [31:0] PC_nxt      ;              //
    wire          regWrite    ;              //
    wire   [ 4:0] rs1, rs2, rd;              //
    wire   [31:0] rs1_data    ;              //
    wire   [31:0] rs2_data    ;              //
    wire   [31:0] rd_data     ;              //
    //---------------------------------------//

    // Todo: other wire/reg

    reg [31:0] instruction;
    reg [31:0] alu_result;

    reg wen_D_reg;
    reg [31:0] addr_D_reg;
    reg [31:0] wdata_D_reg;

    reg regWrite_reg;
    reg [31:0] PC_nxt_reg;
    reg [31:0] rd_data_reg;

    wire [31:0] imm;
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;

    //reg valid_mulDiv, ready_mulDiv;
    //reg [31:0] mulDiv_result;

    assign opcode = instruction[6:0];
    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    assign rd = instruction[11:7];
    assign funct3 = instruction[14:12];
    assign funct7 = instruction[31:25];

    assign imm = (opcode == 7'b1101111) ? {instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0} : // JAL
                 (opcode == 7'b1100111 || opcode == 7'b0000011) ? {{20{instruction[31]}}, instruction[31:20]} : // I-type (JALR/LW)
                 (opcode == 7'b0100011) ? {{20{instruction[31]}}, instruction[31:25], instruction[11:7]} : // S-type (SW)
                 (opcode == 7'b1100011) ? {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0} : // B-type
                 {{instruction[31:12], 12'b0}}; // U-type (LUI, AUIPC)

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

    assign regWrite = regWrite_reg;
    assign PC_nxt = PC_nxt_reg;
    assign rd_data = rd_data_reg;

    assign addr_I = PC;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            PC <= 32'h00010000; // Do not modify this value!!!
            instruction <= 32'b0;
        end
        else begin
            PC <= PC_nxt;
            instruction <= rdata_I;
        end
    end

    always @(*) begin
        alu_result = 32'b0;
        addr_D_reg = 32'b0;
        wdata_D_reg = 32'b0;
        wen_D_reg = 1'b0;

        rd_data_reg = 32'b0;
        regWrite_reg = 1'b0;
        PC_nxt_reg = PC + 4;

        case (opcode)
            // R-type instructions: add, sub
            7'b0110011: begin
                case (funct3)
                    3'b000: begin
                        if (funct7 == 7'b0000000) begin
                            alu_result = rs1_data + rs2_data; // ADD
                        end else if (funct7 == 7'b0100000) begin
                            alu_result = rs1_data - rs2_data; // SUB
                        end else begin
                            alu_result = 0;
                        end
                    end
                    //valid_mulDiv = (funct7 == 7'b0000001) ? 1 : 0; // MUL, DIVU, REMU
                    default: alu_result = 0;
                endcase
                rd_data_reg = alu_result;
                regWrite_reg = 1;
            end

            // I-type instructions: addi, slli, srli, srai, slti
            7'b0010011: begin
                case (funct3)
                    3'b000: alu_result = rs1_data + imm; // ADDI
                    3'b001: alu_result = (funct7 == 7'b0000000) ? rs1_data << imm[4:0] : 0; // SLLI
                    3'b101: begin
                        if (funct7 == 7'b0000000) begin
                            alu_result = rs1_data >> imm[4:0]; // SRLI
                        end else if (funct7 == 7'b0100000) begin
                            alu_result = $signed(rs1_data) >>> imm[4:0]; // SRAI
                        end else begin
                            alu_result = 0;
                        end
                    end
                    3'b010: alu_result = (rs1_data < imm) ? 1 : 0; // SLTI
                    default: alu_result = 0;
                endcase
                rd_data_reg = alu_result;
                regWrite_reg = 1;
            end

            // I-type instructions: lw
            7'b0000011: begin
                case (funct3)
                    3'b010: alu_result = rs1_data + imm; // LW
                    default: alu_result = 0;
                endcase
                addr_D_reg = alu_result;
                wen_D_reg = 1'b0;
                rd_data_reg = rdata_D;
                regWrite_reg = 1'b1;
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
                    PC_nxt_reg = PC + imm;
                end
            end

            // S-type instructions: sw
            7'b0100011: begin
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
                alu_result = PC + imm; // JAL
                PC_nxt_reg = alu_result;
                rd_data_reg = PC + 4;
                regWrite_reg = 1;
            end

            // I-type instructions: jalr
            7'b1100111: begin
                case (funct3)
                    3'b000: alu_result = (rs1_data + imm) & ~1; // JALR
                    default: alu_result = 0;
                endcase
                PC_nxt_reg = alu_result;
                rd_data_reg = PC + 4;
                regWrite_reg = 1;
            end

            // U-type instructions: auipc
            7'b0010111: begin
                alu_result = PC + imm; // AUIPC
                rd_data_reg = alu_result;
                regWrite_reg = 1;
            end

            // U-type instructions: lui
            7'b0110111: begin
                alu_result = imm; // LUI
                rd_data_reg = alu_result;
                regWrite_reg = 1;
            end

            default: alu_result = 0;
        endcase
    end

    /*always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_mulDiv <= 0;
            ready_mulDiv <= 0;
        end else if (opcode == 7'b0110011 && (funct7 == 7'b0000001)) begin // mul, divu, remu
            valid_mulDiv <= 1;
            ready_mulDiv <= (ready_mulDiv == 32) ? 1 : 0; // Simulate 32-cycle delay
            if (ready_mulDiv)
                reg0.mem[rd] <= mulDiv_result;
        end
    end*/
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

module mulDiv(
    input         clk,
    input         rst_n,
    input         valid,
    output        ready,
    input  [1:0]  mode,
    input  [31:0] in_A,
    input  [31:0] in_B,
    output [31:0] out
);
    // Todo: your HW2 logic for MUL/DIV/REMU
    // Currently, leave this as a placeholder if not implemented
    assign ready = 1'b0;
    assign out = 32'b0;

endmodule
