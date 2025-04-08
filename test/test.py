import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import random

# Constants
CLK_PERIOD_NS = 100  # 10 MHz clock (100 ns period)
BAUD_RATE = 9600
CLK_PER_BIT = 10_000_000 // BAUD_RATE  # Clock cycles per UART bit
BIT_TIME_NS = CLK_PERIOD_NS * CLK_PER_BIT  # Time for one UART bit in ns

# Helper function to send a UART byte
async def send_uart_byte(dut, byte):
    dut.ui_in[7].value = 0  # Start bit
    await Timer(BIT_TIME_NS, units="ns")
    for i in range(8):
        dut.ui_in[7].value = (byte >> i) & 1  # Data bits
        await Timer(BIT_TIME_NS, units="ns")
    dut.ui_in[7].value = 1  # Stop bit
    await Timer(BIT_TIME_NS, units="ns")

# Helper function to reset the DUT
async def reset_dut(dut):
    dut.rst_n.value = 0  # Active-low reset
    dut.ena.value = 1    # Enable the design
    dut.ui_in.value = 0  # UART RX idle high (ui_in[7] will be set separately)
    dut.uio_in.value = 0 # SPI MISO and other inputs
    await Timer(200, units="ns")  # Hold reset for 200 ns
    dut.rst_n.value = 1  # Release reset
    await Timer(100, units="ns")  # Wait after reset

# Main test
@cocotb.test()
async def test_riscv_processor(dut):
    # Start the clock
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())

    # Reset the DUT
    await reset_dut(dut)

    # Log initial state
    dut._log.info("Reset released")

    # Program the RAM via UART
    # Word 0 (addr 0): ADDI x1, x0, 1 (0x00000193)
    # Word 1 (addr 1): LW x3, 0(x2) (0x00008103)
    dut._log.info("Starting UART programming")
    await send_uart_byte(dut, 0x00)  # Address 0
    await send_uart_byte(dut, 0x93)  # ADDI x1, x0, 1
    await send_uart_byte(dut, 0x01)
    await send_uart_byte(dut, 0x00)
    await send_uart_byte(dut, 0x00)
    await send_uart_byte(dut, 0x01)  # Address 1
    await send_uart_byte(dut, 0x03)  # LW x3, 0(x2)
    await send_uart_byte(dut, 0x81)
    await send_uart_byte(dut, 0x00)
    await send_uart_byte(dut, 0x00)
    dut._log.info("UART programming completed")

    # Monitor ProgMode and ExecEnable over time
    for i in range(100):  # Monitor for 100 cycles (10 us)
        await Timer(100_000, units="ns")  # 100 us intervals
        prog_mode = dut.tt_um_trishna_test.Processor.prog_mode.value.integer
        exec_enable = dut.tt_um_trishna_test.Processor.exec_enable.value.integer
        dut._log.info(f"Time={cocotb.utils.get_sim_time('ns'):.2f}ns | ProgMode={prog_mode} | ExecEnable={exec_enable}")

    # Wait for execution to start (after prog_mode drops)
    await Timer(5_000_000, units="ns")  # 5 ms

    # Monitor execution
    for _ in range(20):  # Monitor 20 cycles to catch more execution
        await RisingEdge(dut.clk)
        # Access signals with updated hierarchy
        pc = dut.tt_um_trishna_test.Processor.pc_module.pc.value.integer
        instr = dut.tt_um_trishna_test.Processor.im_module.instruction_out.value.integer
        alu_result = dut.tt_um_trishna_test.Processor.ALU_module.ALUResult.value.integer
        write_data = dut.tt_um_trishna_test.Processor.write_data.value.integer
        reg_write = dut.tt_um_trishna_test.Processor.CU_module.reg_write.value.integer
        read_data1 = dut.tt_um_trishna_test.Processor.register_module.read_data1.value.integer
        read_data2 = dut.tt_um_trishna_test.Processor.register_module.read_data2.value.integer
        imm_ext = dut.tt_um_trishna_test.Processor.immediate_module.imm_ext.value.integer
        alu_src = dut.tt_um_trishna_test.Processor.CU_module.alu_src.value.integer
        alu_op = dut.tt_um_trishna_test.Processor.CU_module.alu_op.value.integer
        mem_read = dut.tt_um_trishna_test.Processor.CU_module.mem_read.value.integer
        prog_mode = dut.tt_um_trishna_test.Processor.prog_mode.value.integer
        exec_enable = dut.tt_um_trishna_test.Processor.exec_enable.value.integer
        spi_cs = dut.uio_out[0].value.integer
        dut._log.info(f"PC=0x{pc:08x} | Instr=0x{instr:08x} | ALUResult=0x{alu_result:08x} | WriteData=0x{write_data:08x} | ReadData1=0x{read_data1:08x} | ReadData2=0x{read_data2:08x} | ImmExt=0x{imm_ext:08x} | RegWrite={reg_write} | ALUSrc={alu_src} | ALUOp={alu_op} | MemRead={mem_read} | ProgMode={prog_mode} | ExecEnable={exec_enable} | SPI_CS={spi_cs}")

    # Simulate SPI response
    dut._log.info("Simulating SPI response")
    dut.uio_in[1].value = 1  # Dummy SPI data bit
    await Timer(500_000, units="ns")  # 0.5 ms

    # Wait and finish
    await Timer(1_000_000, units="ns")  # 1 ms
    dut._log.info("Simulation finished")

    # Verify results
    # Expected after execution:
    # x1 = 1 (from ADDI x1, x0, 1)
    # x2 = 8 (from ADDI x2, x0, 8 in ROM)
    # x3 = SPI data (dummy 0xFFFFFFFF due to uio_in[1]=1)
    #assert dut.tt_um_trishna_test.Processor.register_module.reg_file[1].value.integer == 1, "Register x1 should be 1"
    #assert dut.tt_um_trishna_test.Processor.register_module.reg_file[2].value.integer == 8, "Register x2 should be 8"
    #assert dut.tt_um_trishna_test.Processor.register_module.reg_file[3].value.integer == 0xFFFFFFFF, "Register x3 should be 0xFFFFFFFF (SPI data)"