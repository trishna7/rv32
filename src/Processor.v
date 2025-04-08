`default_nettype none
module Processor (
    input clk,
    input reset,
    input uart_rx,
    output wire uart_tx,
    output reg spi_cs,
    output reg spi_sck,
    output reg spi_mosi,
    input spi_miso
);
    wire [6:0] opcode = instruction_out[6:0];
    wire [1:0] alu_op, result_src;
    wire branch, alu_src, reg_write, mem_read, mem_write;
    wire [31:0] pc, pc_next, pc_target, pcplus4;
    wire [31:0] instruction_out;
    wire [4:0] rs1 = instruction_out[19:15];
    wire [4:0] rs2 = instruction_out[24:20];
    wire [4:0] rd = instruction_out[11:7];
    reg [31:0] write_data;
    wire [31:0] read_data1, read_data2;
    wire [2:0] imm_src;
    wire [31:0] imm_ext;
    wire [3:0] alu_control;
    wire [31:0] ALUResult;
    wire zero, pc_src, jump, jal_src, u_src;

    wire [7:0] rx_data;
    wire rx_ready;
    reg prog_mode;
    reg [2:0] prog_state;
    reg [2:0] prog_addr;
    reg [31:0] prog_data;
    reg prog_write;
    wire [7:0] tx_data = ALUResult[7:0];
    reg tx_start;
    wire tx_busy;
    reg exec_enable;

    reg [31:0] spi_data_out;
    reg [31:0] spi_address;
    reg spi_read, spi_write;

    uart_rx uart_rx_inst (
        .clk(clk), .reset(reset), .uart_rx(uart_rx), .data_out(rx_data), .data_ready(rx_ready)
    );
    uart_tx uart_tx_inst (
        .clk(clk), .reset(reset), .data_in(tx_data), .tx_start(tx_start), .uart_tx(uart_tx), .tx_busy(tx_busy)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            prog_mode <= 1;
            prog_state <= 0;
            prog_addr <= 0;
            prog_data <= 0;
            prog_write <= 0;
            tx_start <= 0;
            exec_enable <= 0;
        end
        else if (prog_mode && rx_ready) begin
            case (prog_state)
                3'd0: begin prog_addr <= rx_data[2:0]; prog_state <= 1; end
                3'd1: begin prog_data[7:0] <= rx_data; prog_state <= 2; end
                3'd2: begin prog_data[15:8] <= rx_data; prog_state <= 3; end
                3'd3: begin prog_data[23:16] <= rx_data; prog_state <= 4; end
                3'd4: begin prog_data[31:24] <= rx_data; prog_state <= 0; prog_write <= 1;
                       if (prog_addr == 3'd1) begin prog_mode <= 0; exec_enable <= 1; end
                end
            endcase
        end
        else begin
            prog_write <= 0;
            tx_start <= !tx_busy;
        end
    end

    PC pc_module (
        .clk(clk), .reset(reset), .exec_enable(exec_enable), .pc_src(pc_src), .pc_next(pc_next),
        .pc_target(pc_target), .pcplus4(pcplus4), .pc(pc)
    );
    Instruction_Memory im_module (
        .clk(clk), .reset(reset), .prog_mode(prog_mode), .prog_addr(prog_addr), .prog_data(prog_data),
        .prog_write(prog_write), .read_address(pc), .instruction_out(instruction_out)
    );
    Registers register_module (
        .clk(clk), .reset(reset), .rs1(rs1), .rs2(rs2), .rd(rd), .write_enable(reg_write),
        .write_data(write_data), .read_data1(read_data1), .read_data2(read_data2)
    );
    immediate immediate_module (
        .instruction(instruction_out[31:7]), .imm_src(imm_src), .imm_ext(imm_ext)
    );
    alu_decoder alu_decoder_module (
        .opcode_bit5(instruction_out[4]), .funct3(instruction_out[14:12]), .funct7_bit5(instruction_out[29]),
        .alu_op(alu_op), .alu_control(alu_control)
    );
    ALU ALU_module (
        .srcA(read_data1), .srcB(read_data2), .imm_alu(imm_ext), .alu_control(alu_control), .alu_src(alu_src),
        .ALUResult(ALUResult), .zero(zero)
    );
    Control_unit CU_module (
        .opcode(opcode), .zero(zero), .pc_src(pc_src), .reg_write(reg_write), .imm_src(imm_src),
        .alu_src(alu_src), .mem_write(mem_write), .mem_read(mem_read), .result_src(result_src), .branch(branch),
        .alu_op(alu_op), .jump(jump), .jal_src(jal_src), .u_src(u_src)
    );

    always @(posedge clk) begin
        if (reset) begin
            spi_cs <= 1;
            spi_sck <= 0;
            spi_mosi <= 0;
            spi_read <= 0;
            spi_write <= 0;
            spi_address <= 0;
            spi_data_out <= 0;
        end
        else if (mem_read) begin
            spi_address <= {read_data1[23:0], 8'b0};  // 24-bit address
            spi_read <= 1;
            spi_cs <= 0;
            if (spi_sck) begin
                spi_mosi <= spi_address[31];
                spi_address <= {spi_address[30:0], 1'b0};
            end
            else begin
                spi_data_out <= {spi_data_out[30:0], spi_miso};
            end
            if (spi_address == 0) begin
                spi_cs <= 1;
                spi_read <= 0;
            end
        end
        else if (mem_write) begin
            spi_address <= {read_data1[23:0], 8'b0};
            spi_data_out <= read_data2;
            spi_write <= 1;
            spi_cs <= 0;
            if (spi_sck) begin
                spi_mosi <= spi_address[31];
                spi_address <= {spi_address[30:0], 1'b0};
            end
            else begin
                spi_mosi <= spi_data_out[31];
                spi_data_out <= {spi_data_out[30:0], 1'b0};
            end
            if (spi_address == 0) begin
                spi_cs <= 1;
                spi_write <= 0;
            end
        end
        else begin
            spi_sck <= 0;
            spi_read <= 0;
            spi_write <= 0;
        end
    end

    assign pcplus4 = pc + 4;
    assign pc_target = jal_src ? (read_data1 + imm_ext) : (pc + imm_ext);
    assign pc_next = pc_src ? pc_target : pcplus4;

    always @(*) begin
        case (result_src)
            2'b00: write_data = ALUResult;
            2'b01: write_data = spi_data_out;  // SPI data read
            2'b10: write_data = pcplus4;
            2'b11: write_data = u_src ? (pc + (imm_ext << 12)) : (imm_ext << 12);
            default: write_data = ALUResult;
        endcase
    end
endmodule
