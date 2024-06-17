`timescale 1ns / 1ps

module RV32I (
    input  logic       clk,
    input  logic       reset,
    inout  logic [15:0] IOPortA,
    inout  logic [15:0] IOPortB,
    output logic [ 7:0] fndFont,
    output logic [ 3:0] fndCom,
    input  logic        UART_RX1,
    output logic        UART_TX1
    //inout  logic [15:0] IOPortC,  
    //inout  logic [15:0] IOPortD
    //inout  logic [15:0] IOPortE,
    //inout  logic [15:0] IOPortH  
); 

  logic w_We; 
  logic [31:0] w_InstrMemAddr, w_instrMemData;
  logic [31:0] w_Addr, w_dataMemRData, w_WData;
  logic [31:0] w_MasterRData, w_GPIORData , w_TIMERRData, w_FNDRData,w_UARTRData;
  logic [4:0] w_slave_sel;


  CPU_Core U_CPU_Core (
      .clk          (clk),
      .reset        (reset),
      .machineCode  (w_instrMemData),
      .instrMemRAddr(w_InstrMemAddr),
      .dataMemRData (w_MasterRData),
      .dataMemWData (w_WData),
      .dataMemRAddr (w_Addr),
      .dataMemWe    (w_We)
  );

  BUS_interconntor U_BUS_InterConn (
      .address     (w_Addr),
      .slave_sel   (w_slave_sel),
      .slave_rdata1(w_dataMemRData),
      .slave_rdata2(w_GPIORData),
      .slave_rdata3(w_TIMERRData), 
      .slave_rdata4(w_UARTRData), 
      .slave_rdata5(w_FNDRData), 
      .master_rdata(w_MasterRData)
  );

  InstructionMemory U_ROM (
      .addr(w_InstrMemAddr),
      .data(w_instrMemData)
  );

  DataMemory U_RAM (
      .clk  (clk),
      .ce   (w_slave_sel[0]),
      .we   (w_We),
      .addr (w_Addr[7:0]),
      .wdata(w_WData),
      .rdata(w_dataMemRData)
  );

  GPIO_BUS U_GPIO(
    .clk(clk),
    .reset(reset),
    .ce(w_slave_sel[1]),
    .we(w_We),
    .addr(w_Addr[11:0]),
    .wdata(w_WData),
    .rdata(w_GPIORData),
    //.IOPortA(),
    //.IOPortB(), 
    .IOPortC(),
    .IOPortD(), 
    .IOPortE(),
    .IOPortH(),
    .IOPortA(IOPortA),
    .IOPortB(IOPortB)
    //.IOPortC(IOPortC),
    //.IOPortD(IOPortD) 
    //.IOPortE(IOPortE),
    //.IOPortH(IOPortH)
);

Timer_BUS U_Timer(
    .clk(clk),
    .reset(reset),
    .ce(w_slave_sel[2]),
    .we(w_We),
    .addr(w_Addr[15:0]),
    .wdata(w_WData),
    .rdata(w_TIMERRData),
    .o_clk1(),
    .o_clk2(),
    .o_clk3(),
    .o_clk4()
);

UART_BUS U_UART(
    .clk(clk),
    .reset(reset),
    .ce(w_slave_sel[3]),
    .we(w_We),
    .addr(w_Addr[11:0]),
    .wdata(w_WData),
    .rdata(w_UARTRData),
    .UART_RX1(UART_RX1),
    .UART_TX1(UART_TX1),
    .UART_RX2(),
    .UART_TX2()
);

fndController U_fndController(
    .clk(clk),
    .reset(reset),
    .ce(w_slave_sel[4]),
    .we(w_We),
    .w_data(w_WData),
    .rdata(w_FNDRData),
    .fndFont(fndFont),
    .fndCom(fndCom)
);



endmodule
