`timescale 1ns / 1ps
 

module Timer_BUS (
    input  logic        clk, 
    input  logic        reset, 
    input  logic        ce,
    input  logic        we,
    input  logic [15:0] addr,
    input  logic [31:0] wdata, 
    output logic [31:0] rdata,
    output logic        o_clk1,
    output logic        o_clk2,
    output logic        o_clk3,
    output logic        o_clk4
);

  logic [3:0] w_slave_sel;
  logic [31:0] w_Timer1RData, w_Timer2RData, w_Timer3RData, w_Timer4RData;

  BUS_Timer U_BUS_Timer (
      .address(addr),
      .ce(ce),
      .slave_sel(w_slave_sel),
      .slave_rdata1(w_Timer1RData),
      .slave_rdata2(w_Timer2RData),
      .slave_rdata3(w_Timer3RData),
      .slave_rdata4(w_Timer4RData),
      .master_rdata(rdata)
  );

  Timerx U_Timer1 (
      .clk(clk),
      .reset(reset),
      .ce(w_slave_sel[0]),
      .we(we),
      .addr(addr),
      .wdata(wdata),
      .rdata(w_Timer1RData),
      .out_clk(o_clk1)
  );

  Timerx U_Timer2 (
      .clk(clk),
      .reset(reset),
      .ce(w_slave_sel[1]),
      .we(we),
      .addr(addr),
      .wdata(wdata),
      .rdata(w_Timer2RData),
      .out_clk(o_clk2)
  );

  Timerx U_Timer3 (
      .clk(clk),
      .reset(reset),
      .ce(w_slave_sel[2]),
      .we(we),
      .addr(addr),
      .wdata(wdata),
      .rdata(w_Timer3RData),
      .out_clk(o_clk3)
  );

  Timerx U_Timer4 (
      .clk(clk),
      .reset(reset),
      .ce(w_slave_sel[3]),
      .we(we),
      .addr(addr),
      .wdata(wdata),
      .rdata(w_Timer4RData),
      .out_clk(o_clk4)
  );

endmodule

module Timerx (
    input  logic        clk,
    input  logic        reset,
    input  logic        ce,
    input  logic        we,
    input  logic [15:0] addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata,
    output logic        out_clk
);
  logic [31:0] CR, CNT, PSC, PSC_reg, ARR, CCR;
  logic [15:0] CR_reg, CNT_reg, ARR_reg, CCR_reg;
  logic PSC_Clk;
  logic PEN, CEN;


  assign PSC = PSC_reg;
  assign CNT = {16'b0, CNT_reg};
  assign ARR = {16'b0, ARR_reg};
  assign CCR = {16'b0, CCR_reg};
  assign PEN = CR[1];
  assign CEN = CR[0];

  always_ff @(posedge clk, posedge reset) begin : blockName
    if (reset) begin
      CR  <= 0;
      PSC_reg <= 0;
      CCR_reg <= 0;
      ARR_reg <= 0;
    end else begin
      if (ce & we) begin
        case (addr[7:0])
          8'h00: CR <= wdata;
          8'h04: PSC_reg <= wdata;
          8'h0c: ARR_reg <= wdata;
          8'h10: CCR_reg <= wdata;
        endcase
      end
    end
  end

  always_comb begin
    if (ce) begin
      case (addr[7:0])
        8'h00:   rdata = CR;
        8'h04:   rdata = PSC;
        8'h08:   rdata = CNT;
        8'h0c:   rdata = ARR;
        8'h10:   rdata = CCR;
        default: rdata = 32'bx;
      endcase
    end
  end

  Presclar_Timer U_Presclar (
      .clk  (clk),
      .reset(reset),
      .PSC  (PSC_reg),
      .o_clk(PSC_Clk)
  );

  Counter_Timer U_Counter (
      .tick (PSC_Clk),
      .reset(reset),
      .CEN  (CEN),
      .PEN  (PEN),
      .ARR  (ARR_reg),
      .CCR  (CCR_reg),
      .CNT  (CNT_reg),
      .PWM  (out_clk)
  );

endmodule

module Presclar_Timer (
    input  logic          clk,
    input  logic          reset,
    input  logic [31:0] PSC, 
    output logic          o_clk
);
  logic [31:0] counter = 0;  //$clog2(100_000)- 1 == log_2(100000 - 1)
  logic r_tick = 0;
  assign o_clk = r_tick;

  always @(posedge clk, posedge reset) begin
    if (reset) begin
      counter <= 0;
    end else begin
      if (counter == (PSC)) begin
        counter <= 0;
        r_tick  <= 1'b1;
      end else begin
        counter <= counter + 1;
        r_tick  <= 1'b0;
      end 
    end
  end

endmodule

module Counter_Timer (
    input  logic        tick,
    input  logic        reset,
    input  logic        CEN,
    input  logic        PEN,
    input  logic [15:0] ARR,
    input  logic [15:0] CCR,
    output logic [15:0] CNT,
    output logic        PWM
);
  logic [16 - 1:0] count;
  logic PWM_reg;

  assign CNT = count;
  assign PWM = PWM_reg;

  always_comb begin
    if (PEN) begin
      PWM_reg = (count < CCR) ? 1'b1 : 1'b0;
    end else begin
      PWM_reg = 1'bx;
    end
  end

  always_ff @(posedge tick, posedge reset) begin
    if (reset == 1'b1) begin
      count <= 0;
    end else begin
      if (CEN) begin
        if (count == ARR - 1) begin
          count <= 0;
        end else begin
          count = count + 1;
        end
      end
    end
  end

endmodule

module BUS_Timer (
    input  logic [15:0] address,
    input  logic        ce,
    output logic [ 3:0] slave_sel,
    input  logic [31:0] slave_rdata1,
    input  logic [31:0] slave_rdata2,
    input  logic [31:0] slave_rdata3,
    input  logic [31:0] slave_rdata4,
    output logic [31:0] master_rdata
);

  decoder_Timer U_Decoder (
      .x (address),
      .ce(ce),
      .y (slave_sel)
  );
 

  mux_Timer U_MUX_rdata (
      .sel(address),
      .ce (ce),
      .a  (slave_rdata1),
      .b  (slave_rdata2),
      .c  (slave_rdata3),
      .d  (slave_rdata4),
      .y  (master_rdata)
  );


endmodule

module decoder_Timer (
    input  logic [15:0] x,
    input  logic        ce,
    output logic [ 3:0] y
);

  always_comb begin : decoder
   y = 4'b0;
    if (ce) begin
      case (x[15:8])  //Address
        8'h1C:   y = 4'b0001;
        8'h1E:   y = 4'b0010;
        8'h20:   y = 4'b0100;
        8'h22:   y = 4'b1000;
        default: y = 4'b0;
      endcase
    end
  end

endmodule

module mux_Timer (
    input  logic [15:0] sel,
    input  logic        ce,
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [31:0] c,
    input  logic [31:0] d,
    output logic [31:0] y
);
  always_comb begin : mux
  y = 32'b0;
    if (ce) begin
      case (sel[15:8])  //Address
        8'h1C:   y = a;
        8'h1E:   y = b;
        8'h20:   y = c;
        8'h22:   y = d;
        default: y = 32'b0;
      endcase
    end
  end

endmodule
