`timescale 1ns / 1ps
module GPIO_BUS (
    input  logic        clk,
    input  logic        reset,
    input  logic        ce,
    input  logic        we,
    input  logic [11:0] addr,
    input  logic [31:0] wdata, 
    output logic [31:0] rdata,
    inout  logic [15:0] IOPortA, 
    inout  logic [15:0] IOPortB,
    inout  logic [15:0] IOPortC,
    inout  logic [15:0] IOPortD,
    inout  logic [15:0] IOPortE,
    inout  logic [15:0] IOPortH
);

  logic [5:0] w_slave_sel;
  logic [31:0] w_GPIOARData, w_GPIOBRData, w_GPIOCRData, w_GPIODRData;
  logic [31:0] w_GPIOERData, w_GPIOHRData;

  BUS_GPIO U_BUS_GPIO (
      .address(addr),
      .ce(ce),
      .slave_sel(w_slave_sel),
      .slave_rdata1(w_GPIOARData),
      .slave_rdata2(w_GPIOBRData),
      .slave_rdata3(w_GPIOCRData),
      .slave_rdata4(w_GPIODRData),
      .slave_rdata5(w_GPIOERData),
      .slave_rdata6(w_GPIOHRData),
      .master_rdata(rdata)
  );

  GPIOx U_GPIOA (
      .clk(clk),
      .reset(reset),
      .ce(w_slave_sel[0]),
      .we(we),
      .addr(addr[7:0]),
      .wdata(wdata),
      .rdata(w_GPIOARData),
      .IOPort(IOPortA)
  );

  GPIOx U_GPIOB (
      .clk(clk),
      .reset(reset),
      .ce(w_slave_sel[1]),
      .we(we),
      .addr(addr[7:0]),
      .wdata(wdata),
      .rdata(w_GPIOBRData),
      .IOPort(IOPortB)
  );

  GPIOx U_GPIOC (
      .clk(clk),
      .reset(reset),
      .ce(w_slave_sel[2]),
      .we(we),
      .addr(addr[7:0]),
      .wdata(wdata),
      .rdata(w_GPIOCRData),
      .IOPort(IOPortC)
  );

  GPIOx U_GPIOD (
      .clk(clk),
      .reset(reset),
      .ce(w_slave_sel[3]),
      .we(we),
      .addr(addr[7:0]),
      .wdata(wdata),
      .rdata(w_GPIODRData), 
      .IOPort(IOPortD)
  ); 
  GPIOx U_GPIOE (
      .clk(clk),
      .reset(reset),
      .ce(w_slave_sel[4]),
      .we(we), 
      .addr(addr[7:0]),
      .wdata(wdata),
      .rdata(w_GPIOERData),
      .IOPort(IOPortE)
  ); 
  GPIOx U_GPIOH (
      .clk(clk),
      .reset(reset),
      .ce(w_slave_sel[5]),
      .we(we),
      .addr(addr[7:0]),
      .wdata(wdata),
      .rdata(w_GPIOHRData),
      .IOPort(IOPortH)
  );

endmodule
module GPIOx (
    input  logic        clk,
    input  logic        reset,
    input  logic        ce,
    input  logic        we,
    input  logic [ 7:0] addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata,
    inout  logic [15:0] IOPort
);

  logic [31:0] MODER, IDR, ODR;

  always_ff @(posedge clk, posedge reset) begin
    if (reset) begin
      MODER <= 0;
      ODR   <= 0;
    end else begin
      if (ce & we) begin
        case (addr[3:0])
          4'h0: MODER <= wdata;
          4'h4: ODR <= wdata;
        endcase
      end
    end
  end

  always_comb begin
    if (ce) begin
      case (addr[3:0])
        4'h0: rdata = MODER;
        4'h4: rdata = ODR;
        4'h8: rdata = IDR;
        default: rdata = 32'bx;
      endcase
    end
  end

  // integer i;
  // genvar j;
  // //일반적으로 verilog에서는 for 문을 사용하지 않는다. Verilog에서 사용하는 for 문은 사실 generate 문의 일부이다.
  // //loop index는 genvar로 선언하여야 하며, generate loop 내에서 선언된 wire 등은 loop iteration 간의 충돌이 일어나지 않는다.(local 변수로 이해하면 된다.)

  always_comb begin
    IDR[0]  = MODER[0] ? 1'bz : IOPort[0];
    IDR[1]  = MODER[1] ? 1'bz : IOPort[1];
    IDR[2]  = MODER[2] ? 1'bz : IOPort[2];
    IDR[3]  = MODER[3] ? 1'bz : IOPort[3];
    IDR[4]  = MODER[4] ? 1'bz : IOPort[4];
    IDR[5]  = MODER[5] ? 1'bz : IOPort[5];
    IDR[6]  = MODER[6] ? 1'bz : IOPort[6];
    IDR[7]  = MODER[7] ? 1'bz : IOPort[7];
    IDR[8]  = MODER[8] ? 1'bz : IOPort[8];
    IDR[9]  = MODER[9] ? 1'bz : IOPort[9];
    IDR[10] = MODER[10] ? 1'bz : IOPort[10];
    IDR[11] = MODER[11] ? 1'bz : IOPort[11];
    IDR[12] = MODER[12] ? 1'bz : IOPort[12];
    IDR[13] = MODER[13] ? 1'bz : IOPort[13];
    IDR[14] = MODER[14] ? 1'bz : IOPort[14];
    IDR[15] = MODER[15] ? 1'bz : IOPort[15];
  end

  assign IOPort[0]  = MODER[0] ? ODR[0] : 1'bz;
  assign IOPort[1]  = MODER[1] ? ODR[1] : 1'bz;
  assign IOPort[2]  = MODER[2] ? ODR[2] : 1'bz;
  assign IOPort[3]  = MODER[3] ? ODR[3] : 1'bz;
  assign IOPort[4]  = MODER[4] ? ODR[4] : 1'bz;
  assign IOPort[5]  = MODER[5] ? ODR[5] : 1'bz;
  assign IOPort[6]  = MODER[6] ? ODR[6] : 1'bz;
  assign IOPort[7]  = MODER[7] ? ODR[7] : 1'bz;
  assign IOPort[8]  = MODER[8] ? ODR[8] : 1'bz;
  assign IOPort[9]  = MODER[9] ? ODR[9] : 1'bz;
  assign IOPort[10] = MODER[10] ? ODR[10] : 1'bz;
  assign IOPort[11] = MODER[11] ? ODR[11] : 1'bz;
  assign IOPort[12] = MODER[12] ? ODR[12] : 1'bz;
  assign IOPort[13] = MODER[13] ? ODR[13] : 1'bz;
  assign IOPort[14] = MODER[14] ? ODR[14] : 1'bz;
  assign IOPort[15] = MODER[15] ? ODR[15] : 1'bz;

endmodule


module BUS_GPIO (
    input logic [11:0] address,
    input logic ce,
    output logic [5:0] slave_sel,
    input logic [31:0] slave_rdata1,
    input logic [31:0] slave_rdata2,
    input logic [31:0] slave_rdata3,
    input logic [31:0] slave_rdata4,
    input logic [31:0] slave_rdata5,
    input logic [31:0] slave_rdata6,
    output logic [31:0] master_rdata
);

  decoder_GPIO U_Decoder (
      .x (address),
      .ce(ce),
      .y (slave_sel)
  );


  mux_GPIO U_MUX_rdata (
      .sel(address),
      .ce (ce),
      .a  (slave_rdata1),
      .b  (slave_rdata2),
      .c  (slave_rdata3),
      .d  (slave_rdata4),
      .e  (slave_rdata5),
      .h  (slave_rdata6),
      .y  (master_rdata) 
  ); 

  
endmodule 

module decoder_GPIO ( 
    input  logic [11:0] x,
    input  logic        ce,
    output logic [ 5:0] y
);

  always_comb begin : decoder
  y = 6'b0;
    if (ce) begin
      case (x[11:8])  //Address
        4'h0: y = 6'b000_001;
        4'h2: y = 6'b000_010;
        4'h4: y = 6'b000_100;
        4'h6: y = 6'b001_000;
        4'h8: y = 6'b010_000;
        4'ha: y = 6'b100_000;
        default: y = 6'b0;
      endcase
    end
  end

endmodule

module mux_GPIO (
    input  logic [11:0] sel,
    input  logic        ce,
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [31:0] c,
    input  logic [31:0] d,
    input  logic [31:0] e,
    input  logic [31:0] h,
    output logic [31:0] y
);
  always_comb begin : decoder
  y = 32'b0;
    if (ce) begin
      case (sel[11:8])  //Address
        4'h0: y = a;
        4'h2: y = b;
        4'h4: y = c;
        4'h6: y = d;
        4'h8: y = e;
        4'ha: y = h;
        default: y = 32'b0;
      endcase
    end
  end

endmodule
